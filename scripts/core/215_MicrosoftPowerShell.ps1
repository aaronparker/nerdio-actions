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
    - The installation log is saved in "$Env:SystemRoot\Logs\ImageBuild".
#>

#description: Installs the latest Microsoft PowerShell
#execution mode: Combined
#tags: Evergreen, Microsoft, PowerShell
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\PowerShell"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

#region Script logic
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "MicrosoftPowerShell" | `
    Where-Object { $_.Architecture -eq "x64" -and $_.Release -eq "Stable" } | `
    Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
Write-LogFile -Message "Microsoft PowerShell $($App.Version) downloaded to: $($OutFile.FullName)"

$LogFile = "$Env:SystemRoot\Logs\ImageBuild\MicrosoftPowerShell$($App.Version).log" -replace " ", ""
Write-LogFile -Message "Starting Microsoft PowerShell installation from: $($OutFile.FullName)"
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" /quiet /norestart ALLUSERS=1 /log $LogFile"
}
Start-ProcessWithLog @params
#endregion
