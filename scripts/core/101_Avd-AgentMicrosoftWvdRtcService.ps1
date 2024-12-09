<#
.SYNOPSIS
Installs the latest Microsoft Azure Virtual Desktop agents.

.DESCRIPTION
This script installs the Microsoft Azure Virtual Desktop agents,
including the Microsoft Remote Desktop WebRTC Redirector Service

.PARAMETER Path
The path where the agents will be downloaded. The default path is "$Env:SystemDrive\Apps\Microsoft\Avd".

.NOTES
- Requires the "Evergreen" module.
- Requires administrative privileges.
- This script is intended for use in an Azure Virtual Desktop environment.
#>

#description: Installs the latest Microsoft Azure Virtual Desktop WebRTC Redirector Service
#execution mode: Combined
#tags: Evergreen, Microsoft, AVD
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Avd"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Run tasks/install apps
#region Microsoft Remote Desktop WebRTC Redirector Service
Import-Module -Name "Evergreen" -Force

try {
    $App = Get-EvergreenApp -Name "MicrosoftWvdRtcService" | Where-Object { $_.Architecture -eq "x64" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
}
catch {
    # Workaround if there's a HTTP 502 error
    $App = Get-EvergreenAppFromApi -Name "MicrosoftWvdRtcService" | Where-Object { $_.Architecture -eq "x64" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
}

# Install RTC
$LogFile = "$Env:SystemRoot\Logs\ImageBuild\MicrosoftWvdRtcService$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" /quiet /log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params
#endregion
