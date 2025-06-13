<#
    .SYNOPSIS
    Installs the latest Microsoft PowerToys.

    .DESCRIPTION
    This script installs the latest version of Microsoft PowerToys. It requires the Microsoft .NET Runtime.

    .PARAMETER Path
    The download path for Microsoft PowerToys. The default path is "$Env:SystemDrive\Apps\Microsoft\PowerToys".

    .NOTES
    - This script requires the "Evergreen" module to be installed.
    - The script disables certain features of PowerToys that are not suitable for VDI environments.
#>

#description: Installs the latest Microsoft PowerToys. Requires the Microsoft .NET Runtime
#execution mode: Combined
#tags: Evergreen, Microsoft, PowerToys
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\PowerToys"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import the shared functions
$LogPath = "$Env:ProgramData\ImageBuild"
Import-Module -Name "$LogPath\Functions.psm1" -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $LogPath\Functions.psm1"

#region Script logic
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "MicrosoftPowerToys" | Where-Object { $_.Architecture -eq "x64" -and $_.InstallerType -eq "Default" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
Write-LogFile -Message "Microsoft PowerToys $($App.Version) downloaded to: $($OutFile.FullName)"

$LogFile = "$LogPath\MicrosoftPowerToys$($App.Version).log" -replace " ", ""
Write-LogFile -Message "Starting Microsoft PowerToys installation from: $($OutFile.FullName) with log file: $LogFile"
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "-silent -log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params

# Disable features that aren't suitable for VDI
Write-LogFile -Message "Disabling PowerToys features that are not suitable for VDI environments"
reg add "HKLM\Software\Policies\PowerToys" /v "AllowExperimentation" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityAwake" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityEnvironmentVariables" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityFileLocksmith" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityFileExplorerGcodePreview" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityFileExplorerGcodeThumbnails" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityHostsFileEditor" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityFileExplorerPDFPreview" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityFileExplorerPDFThumbnails" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityFileExplorerQOIPreview" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityFileExplorerQOIThumbnails" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityFileExplorerSTLThumbnails" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityFileExplorerSVGThumbnails" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityVideoConferenceMute" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "DisableNewUpdateAvailableToast" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "AutomaticUpdateDownloadDisabled" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "PerUserInstallationDisabled" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "DoNotShowWhatsNewAfterUpdates" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "SuspendNewUpdateAvailableToast" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityCmdNotFound" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityPeek" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityMouseWithoutBorders" /d 0 /t "REG_DWORD" /f | Out-Null

Start-Sleep -Seconds 5
Get-Process -ErrorAction "SilentlyContinue" | `
    Where-Object { $_.Path -like "$Env:ProgramFiles\PowerToys\*" } | `
    Stop-Process -Force -ErrorAction "SilentlyContinue"
#endregion
