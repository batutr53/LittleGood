$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$target=Join-Path $root 'tools/postgres'
New-Item -ItemType Directory $target -Force | Out-Null
$archive=Join-Path $target 'binaries.zip'
$expected='b9424ee7bc60b52450ff910a3630225df32e633f3cb29c1d126d9299d59aea28'
if(-not (Test-Path $archive)){Invoke-WebRequest 'https://get.enterprisedb.com/postgresql/postgresql-17.11-4-windows-x64-binaries.zip' -OutFile $archive}
if((Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected){throw 'PostgreSQL archive SHA256 mismatch'}
if(-not (Test-Path "$target/pgsql/bin/postgres.exe")){Expand-Archive -LiteralPath $archive -DestinationPath $target}
Write-Output 'Official PostgreSQL 17.11-4 archive verified and extracted. No Windows service installed.'
