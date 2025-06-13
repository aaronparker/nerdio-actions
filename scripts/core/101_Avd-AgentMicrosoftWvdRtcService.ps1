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
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import the shared functions
$LogPath = "$Env:ProgramData\ImageBuild"
Import-Module -Name "$LogPath\Functions.psm1" -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $LogPath\Functions.psm1"

#region Script logic
# Run tasks/install apps
#region Microsoft Remote Desktop WebRTC Redirector Service
try {
    Import-Module -Name "Evergreen" -Force
    Write-LogFile -Message "Downloading Microsoft Remote Desktop WebRTC Redirector Service"
    $App = Get-EvergreenApp -Name "MicrosoftWvdRtcService" | Where-Object { $_.Architecture -eq "x64" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
}
catch {
    # Workaround if there's a HTTP 502 error
    Write-LogFile -Message "Retrying with Get-EvergreenAppFromApi."
    $App = Get-EvergreenAppFromApi -Name "MicrosoftWvdRtcService" | Where-Object { $_.Architecture -eq "x64" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
}

# Install RTC
$LogFile = "$LogPath\MicrosoftWvdRtcService$($App.Version).log" -replace " ", ""
Write-LogFile -Message "Installing Microsoft Remote Desktop WebRTC Redirector Service from: $($OutFile.FullName)"
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
