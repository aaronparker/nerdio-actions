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
    - The script creates a log file in "$Env:SystemRoot\Logs\ImageBuild" directory to track the installation progress and any errors that occur during the installation.
    - The script uses the Start-Process cmdlet to execute the MSI package installation silently.
#>

#description: Installs the latest Microsoft Azure CLI
#execution mode: Combined
#tags: Evergreen, Microsoft, Azure
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\AzureCli"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import the shared functions
$LogPath = "$Env:ProgramData\ImageBuild"
Import-Module -Name "$LogPath\Functions.psm1" -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $LogPath\Functions.psm1"

#region Script logic
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "MicrosoftAzureCLI" | `
    Where-Object { $_.Type -eq "msi" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
Write-LogFile -Message "Microsoft Azure CLI $($App.Version) downloaded to: $($OutFile.FullName)"

$LogFile = "$LogPath\MicrosoftAvdCli$($App.Version).log" -replace " ", ""
Write-LogFile -Message "Starting Microsoft Azure CLI installation from: $($OutFile.FullName)"
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
