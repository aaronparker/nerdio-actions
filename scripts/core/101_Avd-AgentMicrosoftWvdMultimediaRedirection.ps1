<#
    .SYNOPSIS
    Installs the latest Microsoft Azure Virtual Desktop agents.

    .DESCRIPTION
    This script installs the Microsoft Azure Virtual Desktop agents,
    including Microsoft Azure Virtual Desktop Multimedia Redirection Extensions.

    .PARAMETER Path
    The path where the agents will be downloaded. The default path is "$Env:SystemDrive\Apps\Microsoft\Avd".

    .NOTES
    - Requires the "Evergreen" module.
    - Requires administrative privileges.
    - This script is intended for use in an Azure Virtual Desktop environment.
#>

#description: Installs the latest Microsoft Azure Virtual Desktop Multimedia Redirection Extensions
#execution mode: Combined
#tags: Evergreen, Microsoft, AVD
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Avd"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

#region Script logic
# Run tasks/install apps
#region Microsoft Azure Virtual Desktop Multimedia Redirection Extensions
try {
    Import-Module -Name "Evergreen" -Force
    Write-LogFile -Message "Downloading Microsoft Azure Virtual Desktop Multimedia Redirection Extensions"
    $App = Get-EvergreenApp -Name "MicrosoftWvdMultimediaRedirection" | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
}
catch {
    # Workaround if there's a HTTP 502 error
    Write-LogFile -Message "Retrying with Get-EvergreenAppFromApi."
    $App = Get-EvergreenAppFromApi -Name "MicrosoftWvdMultimediaRedirection" | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
}

# Install MMR
$LogPath = (Get-LogFile).Path
$LogFile = "$LogPath\MicrosoftWvdMultimediaRedirection$($App.Version).log" -replace " ", ""
Write-LogFile -Message "Installing Microsoft Azure Virtual Desktop Multimedia Redirection Extensions from: $($OutFile.FullName)"
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" /quiet /log $LogFile"
}
Start-ProcessWithLog @params
#endregion
