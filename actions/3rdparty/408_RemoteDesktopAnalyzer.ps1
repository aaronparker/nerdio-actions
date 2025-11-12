<#
    .SYNOPSIS
    Downloads the Remote Display Analyzer and Connection Experience Indicator to 'C:\Program Files\RemoteDisplayAnalyzer'.

    .DESCRIPTION
    This script downloads the Remote Display Analyzer and Connection Experience Indicator tools to the specified path.
    It creates the necessary directories and imports the required module before downloading the tools.

    .PARAMETER Path
    Specifies the path where the tools will be downloaded. The default path is 'C:\Program Files\RemoteDisplayAnalyzer'.

    .NOTES
    - This script requires the "Evergreen" module to be installed.
    - The script may require administrative privileges to create directories and download the tools.
    - The script may display warnings if the tools are already installed or if there are any issues during the download process.
#>

#description: Downloads the Remote Display Analyzer and Connection Experience Indicator
#execution mode: Combined
#tags: Evergreen, Remote Display Analyzer, Tools
#Requires -Modules Evergreen
[System.String] $Path = "$Env:ProgramFiles\RemoteDisplayAnalyzer"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

Write-LogFile -Message "Query Evergreen for Remote Display Analyzer and Connection Experience Indicator"
$App = Get-EvergreenApp -Name "RDAnalyzer" | Select-Object -First 1
Write-LogFile -Message "Downloading Remote Display Analyzer version $($App.Version) to $Path"
Save-EvergreenApp -InputObject $App -CustomPath $Path -Force -ErrorAction "Stop" | Out-Null

Write-LogFile -Message "Query Evergreen for Connection Experience Indicator"
$App = Get-EvergreenApp -Name "ConnectionExperienceIndicator" | Select-Object -First 1
Write-LogFile -Message "Downloading Connection Experience Indicator version $($App.Version) to $Path"
Save-EvergreenApp -InputObject $App -CustomPath $Path -Force -ErrorAction "Stop" | Out-Null
