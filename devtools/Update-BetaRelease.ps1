param([string]$Archive='C:\LittleGodBeta\incoming\LittleGod-Kingdom-UI.zip')
$ErrorActionPreference='Stop'
$root='C:\LittleGodBeta'
$previous=[IO.File]::ReadAllText("$root\active-release.txt").Trim()
if(-not $previous.StartsWith("$root\releases\",[StringComparison]::OrdinalIgnoreCase)){throw 'Unexpected active release path'}
& "$root\Backup-Database.ps1"
if($LASTEXITCODE){throw 'Backup failed'}
$release=Join-Path "$root\releases" ('kingdom-ui-'+(Get-Date -Format yyyyMMddHHmmss))
Expand-Archive -LiteralPath $Archive -DestinationPath $release
Copy-Item -LiteralPath "$previous\appsettings.Production.json" -Destination "$release\appsettings.Production.json"
& icacls.exe "$release\appsettings.Production.json" /inheritance:r /grant '*S-1-5-32-544:F' '*S-1-5-18:F' | Out-Null
Stop-ScheduledTask -TaskName LittleGodBetaApi
Start-Sleep -Seconds 2
Get-CimInstance Win32_Process -Filter "Name='LittleGod.Api.exe'" | Where-Object {$_.ExecutablePath -eq "$previous\LittleGod.Api.exe"} | ForEach-Object {Stop-Process -Id $_.ProcessId -Force}
[IO.File]::WriteAllText("$root\active-release.txt",$release)
Start-ScheduledTask -TaskName LittleGodBetaApi
$ready=$false
for($i=0;$i -lt 20;$i++){
 Start-Sleep -Seconds 1
 try{$h=Invoke-RestMethod 'http://127.0.0.1:5087/health' -TimeoutSec 2 -Headers @{'X-Forwarded-Proto'='https'};if($h.status -eq 'ok'){$ready=$true;break}}catch{}
}
if(-not $ready){
 Stop-ScheduledTask -TaskName LittleGodBetaApi
 [IO.File]::WriteAllText("$root\active-release.txt",$previous)
 Start-ScheduledTask -TaskName LittleGodBetaApi
 throw 'Health failed; restored previous release pointer'
}
Write-Output ('Updated beta API; backup verified; health OK; release='+$release)
