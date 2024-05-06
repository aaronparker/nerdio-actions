<#
.SYNOPSIS
Installs the latest version of Paint.NET 64-bit with automatic update disabled.

.DESCRIPTION
This script installs the latest version of Paint.NET 64-bit with automatic update disabled.
It uses the Evergreen module to download the Paint.NET installer and extracts it to the specified path.
The script then installs Paint.NET silently using the extracted MSI file.
Finally, it removes the desktop shortcut for Paint.NET.

.PARAMETER Path
The path where Paint.NET will be downloaded. The default value is "$Env:SystemDrive\Apps\Paint.NET".

.NOTES
- This script requires the Evergreen module to be installed.
- The script must be run with administrative privileges.
#>

#description: Installs the latest Paint.NET 64-bit
#execution mode: Combined
#tags: Evergreen, Paint.NET
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Paint.NET"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "PaintDotNetOfflineInstaller" | `
    Where-Object { $_.Architecture -eq "x64" -and $_.URI -match "winmsi" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

$params = @{
    Path            = $OutFile.FullName
    DestinationPath = $Path
    Force           = $true
    ErrorAction     = "Stop"
}
Expand-Archive @params

$Installer = Get-ChildItem -Path $Path -Include "paint*.msi" -Recurse
$LogFile = "$Env:ProgramData\Nerdio\Logs\Paint.NET$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($Installer.FullName)`" DESKTOPSHORTCUT=0 CHECKFORUPDATES=0 CHECKFORBETAS=0 /quiet /log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:Public\Desktop\Paint.NET.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
