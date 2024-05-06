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

if ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption -like "Microsoft Windows 1*") {
    # Prevent Windows from installing stuff during deployment
    reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /d 1 /t "REG_DWORD" /f | Out-Null
    reg add "HKLM\Software\Policies\Microsoft\WindowsStore" /v "AutoDownload" /d 2 /t "REG_DWORD" /f | Out-Null
}

# Start menu customisation
# reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SpecialRoamingOverrideAllowed /t REG_DWORD /d 1 /f

# Enable time zone redirection
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fEnableTimeZoneRedirection /t REG_DWORD /d 1 /f

# Create logs directory and compress
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
$params = @{
    FilePath     = "$Env:SystemRoot\System32\compact.exe"
    ArgumentList = "/C /S `"$Env:ProgramData\Nerdio\Logs`""
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Continue"
}
Start-Process @params *> $null
