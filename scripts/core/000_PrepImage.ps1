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

# Set the log path. This path should survive Sysprep
$LogPath = "$Env:ProgramData\ImageBuild"

# Functions
$Functions = @"
function Write-LogFile {
    param (
        [Parameter(Position = 0, ValueFromPipeline = `$true, Mandatory = `$true)]
        [System.String] `$Message,

        [Parameter(Position = 1, Mandatory = `$false)]
        [ValidateSet(1, 2, 3)]
        [System.Int16] `$LogLevel = 1
    )

    begin {
        `$LogFile = "$LogPath\ImageBuild-`$(Get-Date -Format "yyyy-MM-dd").log"
    }

    process {
        `$TimeGenerated = `$(Get-Date -Format "HH:mm:ss.ffffff")
        `$Context = `$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
        `$Thread = `$([Threading.Thread]::CurrentThread.ManagedThreadId)
        `$LineFormat = `$Message, `$TimeGenerated, (Get-Date -Format "yyyy-MM-dd"), "`$(`$MyInvocation.ScriptName | Split-Path -Leaf -ErrorAction "SilentlyContinue"):`$(`$MyInvocation.ScriptLineNumber)", `$Context, `$LogLevel, `$Thread
        `$Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="{4}" type="{5}" thread="{6}" file="">' -f `$LineFormat
        Write-Information -MessageData "[`$TimeGenerated] `$Message" -InformationAction "Continue"
        Add-Content -Value `$Line -Path `$LogFile
        if (`$LogLevel -eq 3 -or `$LogLevel -eq 2) {
            Write-Warning -Message "[`$TimeGenerated] `$Message"
        }
    }
}

function Get-NerdioVariablesList {
    if (`$null -ne `$SecureVars.VariablesList) {
        try {
            `$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            `$params = @{
                Uri             = `$SecureVars.VariablesList
                UseBasicParsing = `$true
                ErrorAction     = "Stop"
            }
            Write-LogFile -Message "Invoke-RestMethod Nerdio variables list from: `$(`$SecureVars.VariablesList)"
            `$VariableList = Invoke-RestMethod @params
            return `$VariableList
        }
        catch {
            Write-LogFile -Message "Failed with: `$(`$_.Exception.Message)" -LogLevel 3
            throw `$_
        }
    }
    else {
        Write-LogFile -Message "Variable not set: `$(`$SecureVars.VariablesList)" -LogLevel 2
        return `$null
    }
}
"@

# Create logs directory and compress
New-Item -Path $LogPath -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" *> $null
$params = @{
    FilePath     = "$Env:SystemRoot\System32\compact.exe"
    ArgumentList = "/C /S `"$LogPath\*.*`""
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "SilentlyContinue"
}
Start-Process @params *> $null

# Output the functions to the logs directory
$Functions | Out-File -FilePath "$LogPath\Functions.psm1" -Encoding "UTF8" -Force
Import-Module -Name "$LogPath\Functions.psm1" -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $LogPath\Functions.psm1"

# If we're on Windows 11, configure the registry settings
if ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption -like "Microsoft Windows 1*") {
    Write-LogFile -Message "Configuring Windows 11 specific settings"

    # Prevent Windows from installing stuff during deployment
    Write-LogFile -Message "Set: HKLM\Software\Policies\Microsoft\Windows\CloudContent DisableWindowsConsumerFeatures 1"
    reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /d 1 /t "REG_DWORD" /f *> $null
    Write-LogFile -Message "Set: HKLM\Software\Policies\Microsoft\Windows\CloudContent DisableWindowsSpotlightFeatures 1"
    reg add "HKLM\Software\Policies\Microsoft\WindowsStore" /v "AutoDownload" /d 2 /t "REG_DWORD" /f *> $null

    # https://learn.microsoft.com/en-us/windows/deployment/update/waas-wu-settings#allow-windows-updates-to-install-before-initial-user-sign-in
    Write-LogFile -Message "Set: HKLM\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator ScanBeforeInitialLogonAllowed 1"
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator" /v "ScanBeforeInitialLogonAllowed" /d 1 /t "REG_DWORD" /f *> $null 
}

# Enable time zone redirection - this can be configure via policy as well
Write-LogFile -Message "Set: HKLM\Software\Policies\Microsoft\Windows NT\Terminal Services fEnableTimeZoneRedirection 1"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v "fEnableTimeZoneRedirection" /t "REG_DWORD" /d 1 /f *> $null

# Disable remote keyboard layout to keep the locale settings configured in the image
# https://dennisspan.com/solving-keyboard-layout-issues-in-an-ica-or-rdp-session/
Write-LogFile -Message "Set: HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System IgnoreRemoteKeyboardLayout 1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v "IgnoreRemoteKeyboardLayout" /d 1 /t "REG_DWORD" /f *> $null
