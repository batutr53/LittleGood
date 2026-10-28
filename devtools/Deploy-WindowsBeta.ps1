param([string]$Root='C:\LittleGodBeta',[string]$PublicIp='31.42.127.79')
$ErrorActionPreference='Stop'
if($Root -ne 'C:\LittleGodBeta'){throw 'This deployment is scoped to C:\LittleGodBeta.'}
New-Item -ItemType Directory -Force "$Root\tools","$Root\data","$Root\keys","$Root\logs" | Out-Null
# Dedicated application tree only; existing IIS/services and databases are untouched.
$archive="$Root\incoming\postgres.zip"
if(-not(Test-Path -LiteralPath $archive)){Invoke-WebRequest 'https://get.enterprisedb.com/postgresql/postgresql-17.11-4-windows-x64-binaries.zip' -OutFile $archive}
if((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne 'b9424ee7bc60b52450ff910a3630225df32e633f3cb29c1d126d9299d59aea28'){throw 'PostgreSQL archive hash mismatch'}
if(-not(Test-Path "$Root\tools\postgres-runtime.complete")){
 Add-Type -AssemblyName System.IO.Compression.FileSystem
 $zip=[IO.Compression.ZipFile]::OpenRead($archive)
 try{
  foreach($entry in $zip.Entries){
   # Only the database runtime is required, not pgAdmin/StackBuilder or documentation.
   if($entry.FullName -notmatch '^pgsql/(bin|lib|share)/' -or $entry.FullName.EndsWith('/')){continue}
   $destination=Join-Path "$Root\tools" $entry.FullName
   New-Item -ItemType Directory -Force (Split-Path -Parent $destination) | Out-Null
   [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$destination,$true)
  }
 }finally{$zip.Dispose()}
 [IO.File]::WriteAllText("$Root\tools\postgres-runtime.complete",'verified 17.11-4')
}
$pg="$Root\tools\pgsql\bin"
$secretFile="$Root\data\database.secret"
if(-not(Test-Path $secretFile)){
 $random=New-Object byte[] 36;[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($random)
 [IO.File]::WriteAllText($secretFile,[Convert]::ToBase64String($random),[Text.UTF8Encoding]::new($false))
}
$databaseOwner=[Security.Principal.WindowsIdentity]::GetCurrent().Name
& icacls.exe "$Root\data" /inheritance:r /grant '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-18:(OI)(CI)F' "${databaseOwner}:(OI)(CI)F" | Out-Null
$password=[IO.File]::ReadAllText($secretFile)
$data="$Root\data\postgres"
if(-not(Test-Path "$data\PG_VERSION")){
 & "$pg\initdb.exe" -D $data -U littlegod --pwfile=$secretFile --auth=scram-sha-256 --encoding=UTF8 --locale=C
 if($LASTEXITCODE){throw 'Database initialization failed'}
}
& "$pg\pg_ctl.exe" status -D $data | Out-Null
if($LASTEXITCODE){& "$pg\pg_ctl.exe" start -D $data -l "$Root\logs\postgres.log" -o '-h 127.0.0.1 -p 55437';if($LASTEXITCODE){throw 'Database startup failed'}}
$env:PGPASSWORD=$password
try {
 $exists=& "$pg\psql.exe" -h 127.0.0.1 -p 55437 -U littlegod -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='littlegod'"
 if($exists -ne '1'){& "$pg\createdb.exe" -h 127.0.0.1 -p 55437 -U littlegod littlegod;if($LASTEXITCODE){throw 'Database creation failed'}}
}finally{Remove-Item Env:PGPASSWORD}
$release="$Root\releases\$(Get-Date -Format yyyyMMddHHmmss)"
Expand-Archive -LiteralPath "$Root\incoming\LittleGod-Api-win-x64.zip" -DestinationPath $release
$config=@{ConnectionStrings=@{Universe="Host=127.0.0.1;Port=55437;Database=littlegod;Username=littlegod;Password=$password"};DataProtectionDirectory="$Root\keys";MigrateOnStart=$true;Urls='http://127.0.0.1:5087';Logging=@{LogLevel=@{Default='Warning';'Microsoft.AspNetCore'='Warning'}}}
[IO.File]::WriteAllText("$release\appsettings.Production.json",($config|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
& icacls.exe "$release\appsettings.Production.json" /inheritance:r /grant '*S-1-5-32-544:F' '*S-1-5-18:F' | Out-Null
[IO.File]::WriteAllText("$Root\active-release.txt",$release)
$runner=@'
$ErrorActionPreference='Stop'
$root='C:\LittleGodBeta'
$pg="$root\tools\pgsql\bin"
& "$pg\pg_ctl.exe" status -D "$root\data\postgres" | Out-Null
if($LASTEXITCODE){& "$pg\pg_ctl.exe" start -D "$root\data\postgres" -l "$root\logs\postgres.log" -o '-h 127.0.0.1 -p 55437'}
$release=[IO.File]::ReadAllText("$root\active-release.txt").Trim()
Set-Location $release
$env:ASPNETCORE_ENVIRONMENT='Production'
& "$release\LittleGod.Api.exe" *>> "$root\logs\api.log"
'@
[IO.File]::WriteAllText("$Root\Run-Api.ps1",$runner,[Text.UTF8Encoding]::new($false))
Copy-Item -LiteralPath "$Root\incoming\caddy.exe" -Destination "$Root\tools\caddy.exe" -Force
$principal=New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings=New-ScheduledTaskSettingsSet -RestartCount 20 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero) -StartWhenAvailable -MultipleInstances IgnoreNew
$trigger=New-ScheduledTaskTrigger -AtStartup
$apiAction=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -File C:\LittleGodBeta\Run-Api.ps1" -WorkingDirectory $Root
Register-ScheduledTask -TaskName LittleGodBetaApi -Action $apiAction -Principal $principal -Settings $settings -Trigger $trigger -Force | Out-Null
Start-ScheduledTask -TaskName LittleGodBetaApi
Write-Output 'Local beta API started. Run Configure-BetaIpTls.ps1 to configure public HTTPS on 8443 without altering the existing 443 mapping.'
