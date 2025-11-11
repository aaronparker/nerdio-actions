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
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"


Write-LogFile -Message "Query Evergreen for Greenshot"
$App = Get-EvergreenApp -Name "Greenshot" | Where-Object { $_.Type -eq "exe" -and $_.InstallerType -eq "Default" } | Select-Object -First 1
Write-LogFile -Message "Downloading Greenshot version $($App.Version) to $Path"
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$LogPath = (Get-LogFile).Path
$LogFile = "$LogPath\Greenshot$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /TASKS= /FORCECLOSEAPPLICATIONS /LOGCLOSEAPPLICATIONS /NORESTARTAPPLICATIONS /LOG=$LogFile"
    Wait         = $false
}
Start-ProcessWithLog @params

# Close Greenshot
Start-Sleep -Seconds 20
Get-Process -ErrorAction "SilentlyContinue" | `
    Where-Object { $_.Path -like "$Env:ProgramFiles\Greenshot\*" } | ForEach-Object {
    Write-LogFile -Message "Stopping Greenshot process: $($_.Name)"
    $_ | Stop-Process -Force -ErrorAction "SilentlyContinue"
}

# Download the default settings
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {}
else {
    $Variables = Get-NerdioVariablesList
    if ($null -ne $Variables.$AzureRegionName.GreenshotDefaultsIni) {
        Write-LogFile -Message "Downloading Greenshot defaults.ini from $($Variables.$AzureRegionName.GreenshotDefaultsIni)"
        $params = @{
            Uri             = $Variables.$AzureRegionName.GreenshotDefaultsIni
            OutFile         = "$Env:ProgramFiles\Greenshot\greenshot-defaults.ini"
            UseBasicParsing = $true
            ErrorAction     = "Continue"
        }
        Invoke-WebRequest @params
    }
}

# Remove unneeded shortcuts
$Shortcuts = @("$Env:Public\Desktop\Greenshot.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\Greenshot\License.txt.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\Greenshot\Readme.txt.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\Greenshot\Uninstall Greenshot.lnk")
Write-LogFile -Message "Removing Greenshot shortcuts"
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
