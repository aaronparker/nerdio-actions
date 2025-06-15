<#
    .SYNOPSIS
    Installs the Microsoft .NET Desktop LTS and Current Runtimes.

    .DESCRIPTION
    This script installs the Microsoft .NET Desktop LTS (Long-Term Support) and Current Runtimes.
    It uses the Evergreen module to download the appropriate installer and installs it silently with the specified command-line arguments.

    .PARAMETER Path
    The path where the Microsoft .NET runtime will be downloaded. The default path is "$Env:SystemDrive\Apps\Microsoft\NET".

    .EXAMPLE
    .\103_MicrosoftNET.ps1
    Installs the Microsoft .NET Desktop LTS and Current Runtimes using the default installation path.

    .NOTES
    - This script requires the Evergreen module to be installed.
    - The script creates a log file at "$Env:SystemRoot\Logs\ImageBuild\Microsoft.NET.log" to capture installation logs.
#>

#description: Installs the Microsoft .NET Desktop LTS
#execution mode: Combined
#tags: Evergreen, Microsoft, .NET
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\NET"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

#region Script logic
# Download
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "Microsoft.NET" | `
    Where-Object { $_.Installer -eq "windowsdesktop" -and $_.Architecture -eq "x64" -and $_.Channel -match "LTS" }
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$LogPath = (Get-LogFile).Path
foreach ($File in $OutFile) {
    $LogFile = "$LogPath\Microsoft.NET.log" -replace " ", ""
    Write-LogFile -Message "Installing Microsoft .NET Desktop LTS"
    $params = @{
        FilePath     = $File.FullName
        ArgumentList = "/install /quiet /norestart /log $LogFile"
    }
    Start-ProcessWithLog @params
}
#endregion
