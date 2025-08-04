<#
    .SYNOPSIS
    Installs the latest Microsoft Windows App.

    .DESCRIPTION
    This script installs the latest version of the Microsoft Windows App.
    It uses the Evergreen module to retrieve the appropriate version of the client and installs it silently.

    .PARAMETER Path
    The path where the Microsoft Windows App will be downloaded.
    The default path is "$Env:SystemDrive\Apps\Microsoft\Avd".

    .NOTES
    - This script requires the Evergreen module to be installed.
    - The script creates a log file in "$Env:SystemRoot\Logs\ImageBuild" to track the installation progress.
    - The script only installs the x64 version of the client from the "Public" channel.
    - The installation is performed silently without creating a desktop shortcut.
#>

#description: Installs the latest Microsoft Windows App
#execution mode: Combined
#tags: Evergreen, Microsoft, Remote Desktop
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Avd"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

#region Script logic
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "MicrosoftWindowsApp" | `
    Where-Object { $_.Architecture -eq "x64" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
Write-LogFile -Message "Microsoft Windows App $($App.Version) downloaded to: $($OutFile.FullName)"

Write-LogFile -Message "Starting Microsoft Windows App installation from: $($OutFile.FullName)"
$params = @{
    PackagePath = $OutFile.FullName
    Online      = $true
    SkipLicense = $true
    ErrorAction = "Stop"
}
Add-AppxProvisionedPackage @params
#endregion
