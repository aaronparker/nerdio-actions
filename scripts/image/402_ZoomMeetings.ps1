<#
.SYNOPSIS
Installs the latest Zoom Meetings VDI client.

.DESCRIPTION
This script installs the latest Zoom Meetings VDI client by downloading it using the Evergreen module and installing it silently using msiexec.exe.

.PARAMETER Path
The path where the Zoom Meetings VDI client will be downloaded. The default path is "$Env:SystemDrive\Apps\Zoom\Meetings".

.NOTES
- This script requires the Evergreen module to be installed.
- The script creates a log file at "$Env:ProgramData\Nerdio\Logs\ZoomMeetings<version>.log" to track the installation progress.
- The script uses the Start-Process cmdlet to execute msiexec.exe with the necessary arguments for silent installation.
#>

#description: Installs the latest Zoom Meetings VDI client
#execution mode: Combined
#tags: Evergreen, Zoom
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Zoom\Meetings"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Download Zoom
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "ZoomVDI" | Where-Object { $_.Platform -eq "VDIClient" -and $_.Architecture -eq "x64" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$LogFile = "$Env:ProgramData\Nerdio\Logs\ZoomMeetings$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" zSilentStart=false zNoDesktopShortCut=true ALLUSERS=1 /quiet /log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params
#endregion
