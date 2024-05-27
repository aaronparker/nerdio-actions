<#
.SYNOPSIS
Installs the latest VLC media player 64-bit.

.DESCRIPTION
This script installs the latest version of VLC media player (64-bit) on the system.
It utilizes the Evergreen module to download and install the MSI package of VLC media player.
The script also creates necessary directories and removes unnecessary shortcuts.

.PARAMETER Path
The download path for VLC media player. The default path is "$Env:SystemDrive\Apps\VLC\MediaPlayer".

.NOTES
- This script requires the Evergreen module to be installed.
- The script must be run with administrative privileges.
- The script is designed for 64-bit systems.
- The script may take a few seconds to complete the installation process.
#>

#description: Installs the latest VLC media player 64-bit
#execution mode: Combined
#tags: Evergreen, VLC
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\VLC\MediaPlayer"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "VideoLanVlcPlayer" | Where-Object { $_.Architecture -eq "x64" -and $_.Type -eq "MSI" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$LogFile = "$Env:ProgramData\Nerdio\Logs\VlcMediaPlayer$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" ALLUSERS=1 /quiet /log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\VideoLAN\VLC\VideoLAN website.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\VideoLAN\VLC\Release Notes.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\VideoLAN\VLC\Documentation.lnk",
    "$Env:Public\Desktop\VLC media player.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
