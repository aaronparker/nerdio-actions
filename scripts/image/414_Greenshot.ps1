<#
.SYNOPSIS
Installs the latest version of Greenshot.

.DESCRIPTION
This script installs the latest version of Greenshot, a screenshot tool, on the local machine. It performs the following tasks:
- Creates the installation directory for Greenshot.
- Imports the "Evergreen" module for managing application installations.
- Retrieves the latest version of Greenshot from the Evergreen repository.
- Installs Greenshot silently with the specified command-line arguments.
- Closes any running instances of Greenshot.
- Downloads the default settings for Greenshot.
- Removes unnecessary shortcuts.

.PARAMETER Path
The download path for Greenshot. The default value is "$Env:SystemDrive\Apps\Greenshot".

.NOTES
- This script requires the "Evergreen" module to be installed.
- The script may need to be run with administrative privileges.
- The script assumes that the necessary network connectivity is available to download the Greenshot installer and default settings.
#>

#description: Installs the latest version of Greenshot
#execution mode: Combined
#tags: Evergreen, Greenshot
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Greenshot"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "Greenshot" | Where-Object { $_.Type -eq "exe" -and $_.InstallerType -eq "Default" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$LogFile = "$Env:SystemRoot\Logs\ImageBuild\Greenshot$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /TASKS= /FORCECLOSEAPPLICATIONS /LOGCLOSEAPPLICATIONS /NORESTARTAPPLICATIONS /LOG=$LogFile"
    NoNewWindow  = $true
    Wait         = $false
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params

# Close Greenshot
Start-Sleep -Seconds 20
Get-Process -ErrorAction "SilentlyContinue" | `
    Where-Object { $_.Path -like "$Env:ProgramFiles\Greenshot\*" } | `
    Stop-Process -Force -ErrorAction "SilentlyContinue"

# Download the default settings
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {}
else {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $params = @{
        Uri             = $SecureVars.VariablesList
        UseBasicParsing = $true
        ErrorAction     = "Continue"
    }
    $Variables = Invoke-RestMethod @params
    $params = @{
        Uri             = $Variables.$AzureRegionName.GreenshotDefaultsIni
        OutFile         = "$Env:ProgramFiles\Greenshot\greenshot-defaults.ini"
        UseBasicParsing = $true
        ErrorAction     = "Continue"
    }
    Invoke-WebRequest @params
}

# Remove unneeded shortcuts
$Shortcuts = @("$Env:Public\Desktop\Greenshot.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\Greenshot\License.txt.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\Greenshot\Readme.txt.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\Greenshot\Uninstall Greenshot.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
