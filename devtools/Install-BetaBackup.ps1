$ErrorActionPreference='Stop'
$root='C:\LittleGodBeta'
New-Item -ItemType Directory -Force "$root\data\backups" | Out-Null
$script=@'
$ErrorActionPreference='Stop'
$root='C:\LittleGodBeta'
$env:PGPASSWORD=[IO.File]::ReadAllText("$root\data\database.secret")
try {
 $file=Join-Path "$root\data\backups" ((Get-Date -Format yyyyMMdd-HHmmss)+'.dump')
 & "$root\tools\pgsql\bin\pg_dump.exe" -h 127.0.0.1 -p 55437 -U littlegod -d littlegod -Fc -f $file
 if($LASTEXITCODE){throw 'Database backup failed'}
 & "$root\tools\pgsql\bin\pg_restore.exe" --list $file | Out-Null
 if($LASTEXITCODE){throw 'Database backup verification failed'}
}finally{Remove-Item Env:PGPASSWORD}
'@
[IO.File]::WriteAllText("$root\Backup-Database.ps1",$script,[Text.UTF8Encoding]::new($false))
$principal=New-ScheduledTaskPrincipal -UserId SYSTEM -LogonType ServiceAccount -RunLevel Highest
$action=New-ScheduledTaskAction -Execute powershell.exe -Argument '-NoProfile -File C:\LittleGodBeta\Backup-Database.ps1' -WorkingDirectory $root
$settings=New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 1)
Register-ScheduledTask -TaskName LittleGodBetaBackup -Principal $principal -Action $action -Settings $settings -Trigger (New-ScheduledTaskTrigger -Daily -At '04:15') -Force | Out-Null
Start-ScheduledTask -TaskName LittleGodBetaBackup
Write-Output 'Daily database backup installed; backups retained inside the protected data directory.'
