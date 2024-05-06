<#
.SYNOPSIS
Installs the latest Microsoft PowerShell.

.DESCRIPTION
This script installs the latest version of Microsoft PowerShell. It uses the Evergreen module to retrieve the latest stable release of PowerShell and installs it silently. The installation log is saved in the Nerdio Logs directory.

.PARAMETER Path
The installation path for Microsoft PowerShell. The default path is "$Env:SystemDrive\Apps\Microsoft\PowerShell".

.EXAMPLE
.\215_MicrosoftPowerShell.ps1

This example runs the script to install the latest Microsoft PowerShell.

.NOTES
- Requires the Evergreen module.
- Only installs the x64 architecture of Microsoft PowerShell.
- The installation log is saved in "$Env:ProgramData\Nerdio\Logs".
#>

#description: Installs the latest Microsoft PowerShell
#execution mode: Combined
#tags: Evergreen, Microsoft, PowerShell
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\PowerShell"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "MicrosoftPowerShell" | `
    Where-Object { $_.Architecture -eq "x64" -and $_.Release -eq "Stable" } | `
    Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

$LogFile = "$Env:ProgramData\Nerdio\Logs\MicrosoftPowerShell$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" /quiet /norestart ALLUSERS=1 /log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Continue"
}
Start-Process @params
#endregion
