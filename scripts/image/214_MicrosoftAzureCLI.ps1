<#
.SYNOPSIS
Installs the latest Microsoft Azure CLI.

.DESCRIPTION
This script installs the latest version of Microsoft Azure CLI on the local machine.
It uses the Evergreen module to download and install the MSI package for Microsoft Azure CLI.
The installation is performed silently without any user interaction.

.PARAMETER Path
Specifies the download path for Microsoft Azure CLI. The default path is "$Env:SystemDrive\Apps\Microsoft\AzureCli".

.NOTES
- This script requires the Evergreen module to be installed.
- The script creates a log file in "$Env:ProgramData\Nerdio\Logs" directory to track the installation progress and any errors that occur during the installation.
- The script uses the Start-Process cmdlet to execute the MSI package installation silently.
#>

#description: Installs the latest Microsoft Azure CLI
#execution mode: Combined
#tags: Evergreen, Microsoft, Azure
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\AzureCli"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "MicrosoftAzureCLI" | `
    Where-Object { $_.Type -eq "msi" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$LogFile = "$Env:ProgramData\Nerdio\Logs\MicrosoftAvdCli$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" /quiet /norestart ALLUSERS=1 /log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params
#endregion
