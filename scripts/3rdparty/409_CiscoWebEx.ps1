<#
    .SYNOPSIS
    Installs Cisco WebEx VDI client with automatic updates disabled.

    .DESCRIPTION
    This script installs the Cisco WebEx VDI client with automatic updates disabled. The URL to the installer is hard-coded in this script.

    .PARAMETER Path
    Specifies the download path for the Cisco WebEx VDI client.

    .NOTES
    - This script requires the Evergreen module.
    - The installer URL and version number are hard-coded in this script and may need to be updated in the future.
    - This script creates a log file in the ProgramData\Nerdio\Logs directory.

    # https://www.webex.com/downloads/teams-vdi.html
    # https://www.cisco.com/c/en/us/td/docs/voice_ip_comm/cloudCollaboration/wbxt/vdi/wbx-vdi-deployment-guide/wbx-teams-vdi-deployment_chapter_010.html
#>

#description: Installs Cisco WebEx VDI client with automatic updates disabled. URL to the installer is hard coded in this script.
#execution mode: Combined
#tags: Evergreen, Cisco, WebEx
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Cisco\WebEx"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

$App = [PSCustomObject]@{
    Version = "45.6.0.32584"
    URI     = "https://binaries.webex.com/WebexTeamsDesktop-Windows-VDI-gold-Production/20250613015941/WebexVDIPlugin.msi"
}
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$LogPath = (Get-LogFile).Path
$LogFile = "$LogPath\CiscoWebEx$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" ENABLEVDI=2 AUTOUPGRADEENABLED=0 ROAMINGENABLED=1 ALLUSERS=1 /quiet /log $LogFile"
}
Start-ProcessWithLog @params

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:Public\Desktop\WebEx.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"

reg add "HKLM\SOFTWARE\Cisco Spark Native" /v "isVDIEnv" /d "true" /t "REG_EXPAND_SZ" /f | Out-Null
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "CiscoSpark" /f | Out-Null
#endregion
