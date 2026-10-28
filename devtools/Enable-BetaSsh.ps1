param([string]$PublicKeyPath=(Join-Path $PSScriptRoot 'littlegod-beta.pub'))
$ErrorActionPreference='Stop'
$admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run this one-time setup in an elevated PowerShell on the intended beta server.'}
if(-not (Test-Path -LiteralPath $PublicKeyPath -PathType Leaf)){throw 'The companion public key file littlegod-beta.pub is missing.'}
$deployPublicKey=(Get-Content -LiteralPath $PublicKeyPath -Raw).Trim()
if($deployPublicKey -notmatch '^ssh-ed25519 [A-Za-z0-9+/=]+(?: .*)?$'){throw 'Expected an Ed25519 public key, never a private key.'}
$service=Get-Service -Name sshd -ErrorAction SilentlyContinue
if(-not $service){
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null
}
$sshFolder=Join-Path $env:ProgramData 'ssh'
New-Item -ItemType Directory -Path $sshFolder -Force | Out-Null
$authorizedFile=Join-Path $sshFolder 'administrators_authorized_keys'
$knownKeys=if(Test-Path -LiteralPath $authorizedFile){[IO.File]::ReadAllText($authorizedFile)}else{''}
if(-not $knownKeys.Contains(($deployPublicKey -split ' ')[1])){
    $separator=if($knownKeys -and -not $knownKeys.EndsWith("`n")){"`r`n"}else{''}
    [IO.File]::AppendAllText($authorizedFile,$separator+$deployPublicKey+"`r`n",[Text.UTF8Encoding]::new($false))
}
& icacls.exe $authorizedFile /inheritance:r /grant '*S-1-5-32-544:F' '*S-1-5-18:F' | Out-Null
if($LASTEXITCODE){throw 'Could not protect the administrators public-key file.'}
Set-Service -Name sshd -StartupType Automatic
Start-Service -Name sshd
if(-not (Get-NetFirewallRule -Name OpenSSH-Server-In-TCP -ErrorAction SilentlyContinue)){
    New-NetFirewallRule -Name OpenSSH-Server-In-TCP -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
}
Write-Host 'SSH ready. Existing authorized keys were preserved; system protection was not disabled.'
Write-Host ('User: '+$env:USERNAME+'  Port: 22  Computer: '+$env:COMPUTERNAME)
Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*'} | Select-Object InterfaceAlias,IPAddress
Write-Host 'Send the reachable server IP/domain and the user name to continue the beta deployment. No password or private key is needed.'
