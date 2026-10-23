param([switch]$Docker,[switch]$NoApi)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
Set-Location $root
$local=Join-Path $root 'server/.local'
New-Item -ItemType Directory $local -Force | Out-Null
if(-not (Test-Path server/.env)) {
    $bytes=New-Object byte[] 32
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $secret=[Convert]::ToBase64String($bytes)
    [IO.File]::WriteAllText((Join-Path $root 'server/.env'),"POSTGRES_USER=littlegod`nPOSTGRES_DB=littlegod`nPOSTGRES_PASSWORD=$secret`n")
    & icacls.exe server/.env /inheritance:r /grant:r "${env:USERNAME}:(F)" | Out-Null
}
$values=@{}
Get-Content server/.env | ForEach-Object {if($_ -match '^([^#=]+)=(.*)$'){$values[$matches[1]]=$matches[2]}}
if($Docker){docker compose --env-file server/.env -f server/compose.yaml up --build -d; if($LASTEXITCODE){throw 'Docker startup failed'};return}
$pg=Join-Path $root 'tools/postgres/pgsql/bin'
if(-not (Test-Path "$pg/pg_ctl.exe")){throw 'Run devtools/setup_postgres.ps1 first (official verified portable PostgreSQL).'}
$data=Join-Path $local 'postgres'
if(-not (Test-Path "$data/PG_VERSION")) {
    $pw=Join-Path $local 'init-password.tmp'
    [IO.File]::WriteAllText($pw,$values.POSTGRES_PASSWORD)
    try {& "$pg/initdb.exe" -D $data -U $values.POSTGRES_USER --pwfile=$pw --auth=scram-sha-256 --encoding=UTF8 --locale=C; if($LASTEXITCODE){throw 'initdb failed'}}
    finally {Remove-Item -LiteralPath $pw -ErrorAction SilentlyContinue}
}
& "$pg/pg_ctl.exe" status -D $data | Out-Null
if($LASTEXITCODE -ne 0){& "$pg/pg_ctl.exe" start -D $data -l "$local/postgres.log" -o '-h 127.0.0.1 -p 55437';if($LASTEXITCODE){throw 'PostgreSQL startup failed'}}
$env:PGPASSWORD=$values.POSTGRES_PASSWORD
try {
    $exists=& "$pg/psql.exe" -h 127.0.0.1 -p 55437 -U $values.POSTGRES_USER -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='littlegod'"
    if($exists -ne '1'){& "$pg/createdb.exe" -h 127.0.0.1 -p 55437 -U $values.POSTGRES_USER littlegod;if($LASTEXITCODE){throw 'createdb failed'}}
} finally {Remove-Item Env:PGPASSWORD}
if($NoApi){return}
try {
    $existingApi=Invoke-RestMethod 'http://127.0.0.1:5087/health' -TimeoutSec 2 -ErrorAction Stop
    if($existingApi.status -eq 'ok' -and $existingApi.version -eq 1){Write-Output 'LittleGod local API is already running at http://127.0.0.1:5087';return}
} catch { }
$env:ConnectionStrings__Universe="Host=127.0.0.1;Port=55437;Database=littlegod;Username=$($values.POSTGRES_USER);Password=$($values.POSTGRES_PASSWORD)"
$env:ASPNETCORE_ENVIRONMENT='Development'
$env:ASPNETCORE_URLS='http://127.0.0.1:5087'
$env:DataProtectionDirectory=Join-Path $local 'keys'
$env:MigrateOnStart='true'
dotnet run --project server/LittleGod.Api --no-launch-profile
