# cyberpatriot script for windows 10

# Ensure script is run with admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "Please run this script as an Admin!" -ForegroundColor Red
    exit
}

Write-Host "Starting script..." -ForegroundColor Green

# Update machine
Write-Host "Updating Windows and installing patches..." -ForegroundColor Cyan
Install-WindowsUpdate -AcceptAll -AutoReboot

# Enable and Configure Windows Defender
Write-Host "Configuring Windows Defender..." -ForegroundColor Cyan
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -DisableBehaviorMonitoring $false
Set-MpPreference -DisableBlockAtFirstSeen $false
Set-MpPreference -DisableIntrusionPreventionSystem $false
Set-MpPreference -EnableControlledFolderAccess Enabled

# Enable daily scans with WD
Write-Host "Scheduling daily scans with WD..." -ForegroundColor Cyan
schtasks /create /tn "Windows Defender Quick Scan" /sc daily /st 02:00 /ru system /rl highest /tr "powershell.exe -command Start-MpScan -ScanType QuickScan"

# Enable and Configure Firewall
Write-Host "Enabling Windows Firewall..." -ForegroundColor Cyan
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -DefaultOutboundAction Allow
New-NetFirewallRule -DisplayName "Allow RDP" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow

# Disable Unnecessary Services
Write-Host "Disabling unnecessary services..." -ForegroundColor Cyan
Get-Service -Name 'RemoteRegistry','SysMain','RemoteAccess','RemoteDesktopServices' | Stop-Service -Force
Set-Service -Name 'RemoteRegistry','SysMain','RemoteAccess','RemoteDesktopServices' -StartupType Disabled

# Set Strong Password Policy
Write-Host "Enforcing strong password policies..." -ForegroundColor Cyan
secedit /configure /db C:\Windows\Security\Database\SecConfig.sdb /cfg C:\Windows\Security\Templates\securews.inf

# Enable BitLocker Drive Encryption
Write-Host "Enabling BitLocker Drive Encryption..." -ForegroundColor Cyan
$securePassword = Read-Host -Prompt "Enter a BitLocker password" -AsSecureString
Enable-BitLocker -MountPoint "C:" -PasswordProtector -Password $securePassword

# Disable SMBv1 Protocol
Write-Host "Disabling SMBv1 protocol..." -ForegroundColor Cyan
Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol"

# Disable AutoRun and AutoPlay
Write-Host "Disabling AutoRun and AutoPlay..." -ForegroundColor Cyan
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 255 /f

# Enable Windows Update Auto-Install
Write-Host "Configuring automatic Windows updates..." -ForegroundColor Cyan
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 4 /f

# Configure Account Lockout Policy
Write-Host "Configuring account lockout policy..." -ForegroundColor Cyan
net accounts /lockoutthreshold:5 /lockoutduration:30 /lockoutwindow:30

# Enable File and Printer Sharing Protection
Write-Host "Enabling File and Printer Sharing Protection..." -ForegroundColor Cyan
Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Enabled True -Profile Domain,Private -Direction Inbound -Action Allow


# Secure RD (remote desktop) settings
Write-Host "Applying secure RD settings..." -ForegroundColor Cyan
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\' -Name "fDenyTSConnections" -Value 1
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\' -Name "UserAuthentication" -Value 1



# Remove Unnecessary Applications
Write-Host "Removing unnecessary apps..." -ForegroundColor Cyan
Get-AppxPackage *solitaire* | Remove-AppxPackage
Get-AppxPackage *xbox* | Remove-AppxPackage
Get-AppxPackage *3dbuilder* | Remove-AppxPackage
Get-AppxPackage *onenote* | Remove-AppxPackage

Write-Host "Script done!" -ForegroundColor Green
