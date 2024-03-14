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
- The script creates a log file at "$Env:ProgramData\Nerdio\Logs\Microsoft.NET.log" to capture installation logs.
#>

#execution mode: Combined
#tags: Evergreen, Microsoft, .NET
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\NET"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Download
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "Microsoft.NET" | `
    Where-Object { $_.Installer -eq "windowsdesktop" -and $_.Architecture -eq "x64" -and $_.Channel -match "LTS|STS" }
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

Write-Information -MessageData ":: Install Microsoft .NET" -InformationAction "Continue"
foreach ($file in $OutFile) {
    $LogFile = "$Env:ProgramData\Nerdio\Logs\Microsoft.NET.log" -replace " ", ""
    $params = @{
        FilePath     = $file.FullName
        ArgumentList = "/install /quiet /norestart /log $LogFile"
        NoNewWindow  = $true
        PassThru     = $true
        Wait         = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
}
#endregion
