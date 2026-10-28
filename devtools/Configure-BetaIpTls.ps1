$ErrorActionPreference='Stop'
$root='C:\LittleGodBeta'
$module="$root\tools\Posh-ACME"
if(-not(Test-Path "$module\Posh-ACME.psd1")){Expand-Archive -LiteralPath "$root\incoming\Posh-ACME.zip" -DestinationPath $module}
$env:POSHACME_HOME="$root\data\acme"
New-Item -ItemType Directory -Path $env:POSHACME_HOME -Force | Out-Null
Import-Module "$module\Posh-ACME.psd1"
$challenge='C:\inetpub\wwwroot\.well-known\acme-challenge'
New-Item -ItemType Directory -Path $challenge -Force | Out-Null
$webConfig="$challenge\web.config"
if(-not(Test-Path $webConfig)){
 [IO.File]::WriteAllText($webConfig,'<configuration><system.webServer><staticContent><mimeMap fileExtension="." mimeType="text/plain" /></staticContent></system.webServer></configuration>')
}
Set-PAServer LE_PROD
$cert=$null
try{$cert=Get-PACertificate -MainDomain '31.42.127.79'}catch{ }
if(-not $cert){$cert=New-PACertificate '31.42.127.79' -Profile shortlived -Plugin WebRoot -PluginArgs @{WRPath='C:\inetpub\wwwroot'} -AcceptTOS}
$tlsDir="$root\data\tls"
New-Item -ItemType Directory -Path $tlsDir -Force | Out-Null
Copy-Item -LiteralPath $cert.FullChainFile -Destination "$tlsDir\fullchain.pem" -Force
Copy-Item -LiteralPath $cert.KeyFile -Destination "$tlsDir\key.pem" -Force
$caddy=@'
{
 admin 127.0.0.1:2019
 auto_https off
}
https://31.42.127.79:8443 {
 tls C:/LittleGodBeta/data/tls/fullchain.pem C:/LittleGodBeta/data/tls/key.pem
 handle_path /downloads/* {
  root * C:/LittleGodBeta/downloads
  file_server
 }
 handle {
  reverse_proxy 127.0.0.1:5087
 }
 log {
  output file C:/LittleGodBeta/logs/access.log
 }
}
'@
[IO.File]::WriteAllText("$root\Caddyfile",$caddy,[Text.UTF8Encoding]::new($false))
$renew=@'
$ErrorActionPreference='Stop'
$env:POSHACME_HOME='C:\LittleGodBeta\data\acme'
Import-Module C:\LittleGodBeta\tools\Posh-ACME\Posh-ACME.psd1
Set-PAServer LE_PROD
Submit-Renewal -MainDomain '31.42.127.79' | Out-Null
$cert=Get-PACertificate -MainDomain '31.42.127.79'
Copy-Item -LiteralPath $cert.FullChainFile -Destination C:\LittleGodBeta\data\tls\fullchain.pem -Force
Copy-Item -LiteralPath $cert.KeyFile -Destination C:\LittleGodBeta\data\tls\key.pem -Force
$ErrorActionPreference='Continue'
& C:\LittleGodBeta\tools\caddy.exe reload --config C:\LittleGodBeta\Caddyfile --adapter caddyfile --force *>> C:\LittleGodBeta\logs\tls-renewal.log
$reloadCode=$LASTEXITCODE
$ErrorActionPreference='Stop'
if($reloadCode){throw 'TLS reload failed'}
'@
[IO.File]::WriteAllText("$root\Renew-Tls.ps1",$renew,[Text.UTF8Encoding]::new($false))
$runner=@'
Set-Location C:\LittleGodBeta
& C:\LittleGodBeta\tools\caddy.exe run --config C:\LittleGodBeta\Caddyfile --adapter caddyfile *>> C:\LittleGodBeta\logs\tls.log
'@
[IO.File]::WriteAllText("$root\Run-Tls.ps1",$runner,[Text.UTF8Encoding]::new($false))
$principal=New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings=New-ScheduledTaskSettingsSet -RestartCount 20 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero) -StartWhenAvailable -MultipleInstances IgnoreNew
$proxy=New-ScheduledTaskAction -Execute powershell.exe -Argument '-NoProfile -File C:\LittleGodBeta\Run-Tls.ps1' -WorkingDirectory $root
Register-ScheduledTask -TaskName LittleGodBetaTls -Action $proxy -Principal $principal -Settings $settings -Trigger (New-ScheduledTaskTrigger -AtStartup) -Force | Out-Null
$renewAction=New-ScheduledTaskAction -Execute powershell.exe -Argument '-NoProfile -File C:\LittleGodBeta\Renew-Tls.ps1' -WorkingDirectory $root
Register-ScheduledTask -TaskName LittleGodBetaRenew -Action $renewAction -Principal $principal -Settings $settings -Trigger (New-ScheduledTaskTrigger -Daily -At '03:15') -Force | Out-Null
if(-not(Get-NetFirewallRule -Name LittleGodBetaHttps8443 -ErrorAction SilentlyContinue)){New-NetFirewallRule -Name LittleGodBetaHttps8443 -DisplayName 'LittleGod Beta HTTPS 8443' -Direction Inbound -Protocol TCP -LocalPort 8443 -Action Allow | Out-Null}
if((Get-ScheduledTask -TaskName LittleGodBetaTls).State -ne 'Running'){Start-ScheduledTask -TaskName LittleGodBetaTls}
Write-Output ('IP certificate issued; expires '+$cert.NotAfter+'. Endpoint https://31.42.127.79:8443')
