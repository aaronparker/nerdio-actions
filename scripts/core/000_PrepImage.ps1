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
#>

#description: Preps a RDS / AVD image for customization.
#execution mode: Combined
#tags: Image

# If we're on Windows 11, configure the registry settings
if ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption -like "Microsoft Windows 1*") {

    # Prevent Windows from installing stuff during deployment
    reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /d 1 /t "REG_DWORD" /f *> $null
    reg add "HKLM\Software\Policies\Microsoft\WindowsStore" /v "AutoDownload" /d 2 /t "REG_DWORD" /f *> $null

    # https://learn.microsoft.com/en-us/windows/deployment/update/waas-wu-settings#allow-windows-updates-to-install-before-initial-user-sign-in
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator" /v "ScanBeforeInitialLogonAllowed" /d 1 /t "REG_DWORD" /f *> $null 
}

# Enable time zone redirection - this can be configure via policy as well
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v "fEnableTimeZoneRedirection" /t "REG_DWORD" /d 1 /f *> $null

# Disable remote keyboard layout to keep the locale settings configured in the image
# https://dennisspan.com/solving-keyboard-layout-issues-in-an-ica-or-rdp-session/
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v "IgnoreRemoteKeyboardLayout" /d 1 /t "REG_DWORD" /f *> $null

# Create logs directory and compress
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" *> $null
$params = @{
    FilePath     = "$Env:SystemRoot\System32\compact.exe"
    ArgumentList = "/C /S `"$Env:SystemRoot\Logs\ImageBuild`""
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "SilentlyContinue"
}
Start-Process @params *> $null
