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
[System.String] $Path = "$Env:SystemDrive\NotepadPlusPlus"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

Write-LogFile -Message "Query Evergreen for Notepad++ x64"
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "NotepadPlusPlus" | Where-Object { $_.Architecture -eq "x64" -and $_.Type -eq "exe" } | Select-Object -First 1
Write-LogFile -Message "Downloading Notepad++ version $($App.Version) to $Path"
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/S"
}
Start-ProcessWithLog @params

# Disable updater
$UpdaterPath = "$Env:ProgramFiles\Notepad++\updater"
$RenamePath = "$Env:ProgramFiles\Notepad++\updater.disabled"
if (Test-Path -Path $UpdaterPath) {
    if (Test-Path -Path $RenamePath) {
        Remove-Item -Path $RenamePath -Recurse -Force -ErrorAction "SilentlyContinue"
    }
    Rename-Item -Path $UpdaterPath -NewName "updater.disabled" -Force -ErrorAction "SilentlyContinue"
}
