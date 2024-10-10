<#
.SYNOPSIS
Preps a RDS / AVD image for customization.

.DESCRIPTION
This script is used to prepare a RDS (Remote Desktop Services) or AVD (Azure Virtual Desktop) image
for customization. It performs the following tasks:
- Sets a policy to prevent Windows updates during deployment.
- Customizes the Start menu.
- Enables time zone redirection.
- Creates and compresses a logs directory.

.PARAMETER None

.EXAMPLE
.\000_PrepImage.ps1
#>

#description: Preps a RDS / AVD image for customization.
#execution mode: Combined
#tags: Image

# If we're on Windows 11, configure the registry settings
if ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption -like "Microsoft Windows 1*") {
    
    # Prevent Windows from installing stuff during deployment
    reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /d 1 /t "REG_DWORD" /f | Out-Null
    reg add "HKLM\Software\Policies\Microsoft\WindowsStore" /v "AutoDownload" /d 2 /t "REG_DWORD" /f | Out-Null
    
    # https://www.reddit.com/r/Windows11/comments/17toy5k/prevent_automatic_installation_of_outlook_and_dev/
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate" /f | Out-Null
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate" /f | Out-Null
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate" /f | Out-Null
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate" /f | Out-Null

    # https://learn.microsoft.com/en-us/windows/deployment/update/waas-wu-settings#allow-windows-updates-to-install-before-initial-user-sign-in
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator" /v "ScanBeforeInitialLogonAllowed" /d 1 /t "REG_DWORD" /f | Out-Null 
}

# Enable time zone redirection - this can be configure via policy as well
Write-LogFile -Message "Enable time zone redirection" -LogLevel 1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v "fEnableTimeZoneRedirection" /t "REG_DWORD" /d 1 /f

# Create logs directory and compress
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
$params = @{
    FilePath     = "$Env:SystemRoot\System32\compact.exe"
    ArgumentList = "/C /S `"$Env:SystemRoot\Logs\ImageBuild`""
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params | Out-Null
