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

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force

$App = Get-EvergreenApp -Name "RDAnalyzer" | Select-Object -First 1
Save-EvergreenApp -InputObject $App -CustomPath $Path -Force -ErrorAction "Stop" | Out-Null

$App = Get-EvergreenApp -Name "ConnectionExperienceIndicator" | Select-Object -First 1
Save-EvergreenApp -InputObject $App -CustomPath $Path -Force -ErrorAction "Stop" | Out-Null
#endregion
