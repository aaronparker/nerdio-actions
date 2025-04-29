<#
    .SYNOPSIS
    Installs the latest Notepad++ 64-bit with automatic updates disabled.

    .DESCRIPTION
    This script installs the latest version of Notepad++ 64-bit on the local machine. It also disables the automatic update feature of Notepad++.

    .PARAMETER Path
    Specifies the download path for Notepad++. The default path is "$Env:SystemDrive\Apps\NotepadPlusPlus".

    .NOTES
    - This script requires the "Evergreen" module.
    - The script will create a directory at the specified installation path if it does not already exist.
    - The script will create a directory at "$Env:SystemRoot\Logs\ImageBuild" if it does not already exist.
    - The script will download the latest version of Notepad++ from the Evergreen repository and install it silently.
    - The script will disable the automatic update feature of Notepad++ by renaming the updater folder.
#>

#description: Installs the latest Notepad++ 64-bit
#execution mode: Combined
#tags: Evergreen, Notepad++
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\NotepadPlusPlus"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "NotepadPlusPlus" | Where-Object { $_.Architecture -eq "x64" -and $_.Type -eq "exe" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/S"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params

# Disable updater
$UpdaterPath = "$Env:ProgramFiles\Notepad++\updater"
$RenamePath = "$Env:ProgramFiles\Notepad++\updater.disabled"
if (Test-Path -Path $UpdaterPath) {
    if (Test-Path -Path $RenamePath) {
        Remove-Item -Path $RenamePath -Recurse -Force -ErrorAction "SilentlyContinue"
    }
    Rename-Item -Path $UpdaterPath -NewName "updater.disabled" -Force -ErrorAction "SilentlyContinue"
}
#endregion
