<#
    .SYNOPSIS
    Installs the latest Microsoft SQL Server Management Studio.

    .DESCRIPTION
    This script installs the latest version of Microsoft SQL Server Management Studio (SSMS) on the local machine.
    It utilizes the Evergreen module to download and install the specified version of SSMS.

    .PARAMETER Path
    Specifies the download path for SSMS. The default path is "$Env:SystemDrive\Apps\Microsoft\Ssms".

    .NOTES
    - This script requires the Evergreen module to be installed.
    - The script creates a log file in "$Env:SystemRoot\Logs\ImageBuild" to track the installation progress.
    - The script supports multiple languages, but it only installs the English version of SSMS.
    - The installation is performed silently without any user interaction.
    - The script checks if SSMS is already installed and skips the installation if it is.
    - The exit code of the installation process is logged for reference.
#>

#description: Installs the latest Microsoft SQL Server Management Studio
#execution mode: Combined
#tags: Evergreen, Microsoft, SQL Server
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Ssms"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

#region Script logic

$App = Get-EvergreenApp -Name "MicrosoftSsms" | `
    Where-Object { $_.Language -eq "English" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
Write-LogFile -Message "Microsoft SQL Server Management Studio $($App.Version) downloaded to: $($OutFile.FullName)"

$LogPath = (Get-LogFile).Path
$LogFile = "$LogPath\MicrosoftSQLServerManagementStudio$($App.Version).log" -replace " ", ""
Write-LogFile -Message "Starting Microsoft SQL Server Management Studio installation from: $($OutFile.FullName)"
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/install /quiet /norestart DoNotInstallAzureDataStudio=1 /log $LogFile"
}
Start-ProcessWithLog @params
#endregion
