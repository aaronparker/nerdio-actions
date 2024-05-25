<#
.SYNOPSIS
Installs the latest Microsoft Visual Studio Code 64-bit.

.DESCRIPTION
This script installs the latest version of Microsoft Visual Studio Code (64-bit) on a Windows machine. It uses the Evergreen module to retrieve the latest version of Visual Studio Code and installs it silently.

.PARAMETER Path
The download path for Microsoft Visual Studio Code. The default path is "$Env:SystemDrive\Apps\Microsoft\VisualStudioCode".

.NOTES
- This script requires the Evergreen module to be installed.
- The script creates a log file in "$Env:ProgramData\Nerdio\Logs" to track the installation progress.
- The script stops any running instances of Microsoft Visual Studio Code before installing the new version.
#>

#description: Installs the latest Microsoft Visual Studio Code 64-bit
#execution mode: Combined
#tags: Evergreen, Microsoft, Visual Studio Code
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\VisualStudioCode"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "MicrosoftVisualStudioCode" | `
    Where-Object { $_.Architecture -eq "x64" -and $_.Platform -eq "win32-x64" -and $_.Channel -eq "Stable" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

$LogFile = "$Env:ProgramData\Nerdio\Logs\MicrosoftVisualStudioCode$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/VERYSILENT /NOCLOSEAPPLICATIONS /NORESTARTAPPLICATIONS /NORESTART /SP- /SUPPRESSMSGBOXES /MERGETASKS=!runcode /LOG=$LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params

Start-Sleep -Seconds 5
Get-Process -ErrorAction "SilentlyContinue" | `
    Where-Object { $_.Path -like "$Env:ProgramFiles\Microsoft VS Code\*" } | `
    Stop-Process -Force -ErrorAction "SilentlyContinue"


# Disable updates for pooled desktops
reg add "HKLM\Software\Policies\Microsoft\Microsoft\VSCode" /v "UpdateMode" /d "none" /t "REG_SZ" /f | Out-Null
#endregion
