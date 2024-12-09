<#
.SYNOPSIS
Installs the latest Microsoft Azure Virtual Desktop Remote Desktop client.

.DESCRIPTION
This script installs the latest version of the Microsoft Azure Virtual Desktop Remote Desktop client.
It uses the Evergreen module to retrieve the appropriate version of the client and installs it silently.

.PARAMETER Path
The path where the Microsoft Azure Virtual Desktop Remote Desktop client will be downloaded.
The default path is "$Env:SystemDrive\Apps\Microsoft\Avd".

.NOTES
- This script requires the Evergreen module to be installed.
- The script creates a log file in "$Env:SystemRoot\Logs\ImageBuild" to track the installation progress.
- The script only installs the x64 version of the client from the "Public" channel.
- The installation is performed silently without creating a desktop shortcut.
#>

#description: Installs the latest Microsoft Azure Virtual Desktop Remote Desktop client
#execution mode: Combined
#tags: Evergreen, Microsoft, Remote Desktop
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Avd"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "MicrosoftWvdRemoteDesktop" | `
    Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Public" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$LogFile = "$Env:SystemRoot\Logs\ImageBuild\MicrosoftAvdClient$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" /quiet /norestart DONOTCREATEDESKTOPSHORTCUT=true /log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params
#endregion
