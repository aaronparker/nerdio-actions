<#
.SYNOPSIS
    Prepares a Remote Desktop Services (RDS) / Azure Virtual Desktop (AVD) image for customization.

.DESCRIPTION
    This script sets up logging functions, configures Windows registry settings for image deployment, 
    and applies optimizations for Windows 11 and RDS/AVD environments. It includes functions for logging, 
    command execution with logging, and retrieving Nerdio variable lists. The script also applies 
    recommended registry settings for time zone redirection and keyboard layout handling.

.FUNCTIONS
    Get-LogFile
        Returns the log file path and file name for logging operations.

    Test-LogPath
        Ensures the log directory exists and is compressed.

    Write-LogFile
        Writes messages to the log file and outputs to the console, with support for log levels.

    Start-ProcessWithLog
        Executes a command or script with logging and error handling.

    Get-NerdioVariablesList
        Retrieves a list of variables from a specified Nerdio endpoint.

.NOTES
    - Outputs function definitions to a temporary module file and imports them for use.
    - Applies Windows 11 specific registry settings if detected.
    - Enables time zone redirection and disables remote keyboard layout to preserve locale settings.
    - Designed for use in automated image build and customization pipelines.
#>

#description: Preps a RDS / AVD image for customization.
#execution mode: Individual
#tags: Image

# Functions
$Functions = @"
function Get-LogFile {
    [CmdletBinding()]
    `$LogPath = "`$Env:SystemRoot\Logs\ImageBuild"
    `$LogFile = "`$LogPath\ImageBuild-`$(Get-Date -Format "yyyy-MM-dd").log"
    [PSCustomObject]@{
        Path = `$LogPath
        File = `$LogFile
    }
}

function Test-LogPath {
    [CmdletBinding()]
    param (
        [System.String] `$Path
    )

    # Create the log file path
    if (-not(Test-Path -Path `$Path)) {
        try {
            New-Item -Path `$Path -ItemType "Directory" -ErrorAction "Stop" | Out-Null
        }
        catch {
            throw `$_
        }
    }

    # Compress the log directory if it is not already compressed
    `$Attributes = Get-Item -Path `$Path | Select-Object -ExpandProperty "Attributes"
    if (-not(`$Attributes -band [IO.FileAttributes]::Compressed)) {

        # Compress the log directory; backslash needs to be escaped in the CIM query
        `$EscPath = `$Path -replace "\\", "\\"
        [void](Get-CimInstance -Query "SELECT * FROM CIM_Directory WHERE Name = '`$EscPath'" | Invoke-CimMethod -MethodName "Compress")
    }
}

function Write-LogFile {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline = `$true, Mandatory = `$true)]
        [System.String] `$Message,

        [Parameter(Position = 1, Mandatory = `$false)]
        [ValidateSet(1, 2, 3)]
        [System.Int16] `$LogLevel = 1
    )

    begin {
        # Log file path
        `$LogFile = Get-LogFile
        Test-LogPath -Path `$LogFile.Path
    }

    process {
        # Build the line which will be recorded to the log file
        `$TimeGenerated = `$(Get-Date -Format "HH:mm:ss.ffffff")
        `$Context = `$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
        `$Thread = `$([Threading.Thread]::CurrentThread.ManagedThreadId)
        `$LineFormat = `$Message, `$TimeGenerated, (Get-Date -Format "yyyy-MM-dd"), "`$(`$MyInvocation.ScriptName | Split-Path -Leaf -ErrorAction "SilentlyContinue"):`$(`$MyInvocation.ScriptLineNumber)", `$Context, `$LogLevel, `$Thread
        `$Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="{4}" type="{5}" thread="{6}" file="">' -f `$LineFormat

        # Add content to the log file and output to the console
        # Write-Information -MessageData "[`$TimeGenerated] `$Message" -InformationAction "Continue"
        Write-Host "[`$TimeGenerated] `$Message"
        Add-Content -Value `$Line -Path `$LogFile.File

        # Write-Warning for log level 2 or 3
        if (`$LogLevel -eq 3 -or `$LogLevel -eq 2) {
            Write-Warning -Message "[`$TimeGenerated] `$Message"
        }
    }
}

function Start-ProcessWithLog {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [System.String] `$FilePath,

        [Parameter(Position = 1)]
        [System.String] `$ArgumentList,

        [Parameter()]
        [Switch] `$Wait = `$true
    )

    if (Test-Path -Path `$FilePath -PathType "Leaf") {
        try {
            `$params = @{
                FilePath     = `$FilePath
                ArgumentList = `$ArgumentList
                NoNewWindow  = `$true
                PassThru     = `$true
                Wait         = `$Wait
                ErrorAction  = "Stop"
            }
            Write-LogFile -Message "Execute: `$FilePath `$ArgumentList"
            `$Result = Start-Process @params
            Write-LogFile -Message "Exit code: `$(`$Result.ExitCode)"
        }
        catch {
            Write-LogFile -Message "Execution error: `$(`$_.Exception.Message)" -LogLevel 3
        }
    }
    else {
        Write-LogFile -Message "File not found: `$FilePath" -LogLevel 2
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

# Output the functions to the logs directory
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
$Functions | Out-File -FilePath $FunctionFile -Encoding "UTF8" -Force
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

# If we're on Windows 11, configure the registry settings
if ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption -like "Microsoft Windows 1*") {
    Write-LogFile -Message "Configuring Windows 11 specific settings"

    # Prevent Windows from installing stuff during deployment
    Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\Microsoft\Windows\CloudContent /v DisableWindowsConsumerFeatures /d 1 /t REG_DWORD /f"
    Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\Microsoft\Windows\CloudContent /v DisableWindowsSpotlightFeatures /d 1 /t REG_DWORD /f"
    Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\Microsoft\WindowsStore /v AutoDownload /d 2 /t REG_DWORD /f"

    # https://learn.microsoft.com/en-us/windows/deployment/update/waas-wu-settings#allow-windows-updates-to-install-before-initial-user-sign-in
    Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator /v ScanBeforeInitialLogonAllowed /d 1 /t REG_DWORD /f"
}

# Enable time zone redirection - this can be configure via policy as well
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\Software\Policies\Microsoft\Windows NT\Terminal Services" /v fEnableTimeZoneRedirection /d 1 /t REG_DWORD /f'

# Disable remote keyboard layout to keep the locale settings configured in the image
# https://dennisspan.com/solving-keyboard-layout-issues-in-an-ica-or-rdp-session/
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v IgnoreRemoteKeyboardLayout /d 1 /t REG_DWORD /f'

# Trust the PSGallery for modules
Write-LogFile -Message "Install-PackageProvider: PowerShellGet" -LogLevel 1
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Install-PackageProvider -Name "NuGet" -Force
Install-PackageProvider -Name "PowerShellGet" -MinimumVersion "2.2.5" -AllowClobber -Force
Import-Module -Name "PowerShellGet" -Force
Write-LogFile -Message "Set-PSRepository: PSGallery" -LogLevel 1
Set-PSRepository -Name "PSGallery" -InstallationPolicy "Trusted"
