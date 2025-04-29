<#
    .SYNOPSIS
    Installs the latest Microsoft OneDrive per-machine for use on Windows 10/11 multi-session or Windows Server.

    .DESCRIPTION
    This script installs the latest version of Microsoft OneDrive per-machine.
    It uses the Evergreen module to retrieve the latest version of the OneDrive executable and installs it silently with the specified arguments.
    The script also creates the necessary directories and logs for the installation.

    .PARAMETER Path
    The installation path for Microsoft OneDrive. The default path is "$Env:SystemDrive\Apps\Microsoft\OneDrive".

    .EXAMPLE
    .\200_MicrosoftOneDrive.ps1

    This example runs the script and installs the latest version of Microsoft OneDrive per-machine.

    .NOTES
    - This script requires the Evergreen module to be installed.
    - The script is designed to be run on Windows 10/11 multi-session or Windows Server.
    - The script must be run with administrative privileges.
#>

#description: Installs the latest Microsoft OneDrive per-machine for use on Windows 10/11 multi-session or Windows Server
#execution mode: Combined
#tags: Evergreen, Microsoft, OneDrive, per-machine
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\OneDrive"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Run tasks/install apps
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "MicrosoftOneDrive" | `
    Where-Object { $_.Ring -eq "Production" -and $_.Throttle -eq "100" -and $_.Architecture -eq "x64" } | `
    Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

# Install
reg add "HKLM\Software\Microsoft\OneDrive" /v "AllUsersInstall" /t REG_DWORD /d 1 /reg:64 /f
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/silent /allusers"
    NoNewWindow  = $true
    Wait         = $false
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params
do {
    Start-Sleep -Seconds 5
} while (Get-Process -Name "OneDriveSetup" -ErrorAction "SilentlyContinue")
Get-Process -Name "OneDrive" -ErrorAction "SilentlyContinue" | Stop-Process -Force -ErrorAction "SilentlyContinue"
#endregion
