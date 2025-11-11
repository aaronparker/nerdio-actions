<#
    .SYNOPSIS
    Installs the latest Adobe Acrobat Reader MUI 64-bit with automatic updates disabled and forces Reader into read-only mode.

    .DESCRIPTION
    This script installs the latest version of Adobe Acrobat Reader MUI (64-bit) with automatic updates disabled.
    It also enforces read-only mode for Reader. The script downloads the Reader installer, installs it with the specified options,
    and configures the necessary registry settings to enforce read-only mode and disable the Adobe Updater.
    It also disables the AdobeARMservice and the Adobe Acrobat Update Task scheduled task.
    Finally, it removes the public desktop shortcut for Adobe Acrobat.

    .PARAMETER Path
    The path where Adobe Acrobat Reader will be downloaded. The default path is "$Env:SystemDrive\Apps\Adobe\AcrobatReaderDC".

    .NOTES
    - This script requires the Evergreen module to download the Reader installer.
    - Secure variables can be used in Nerdio Manager to pass a JSON file with the variables list.
    - For more information on enforcing settings with Group Policy Objects (GPO), refer to the Adobe Acrobat Enterprise Administration Guide.
    - For more information on installing Adobe Acrobat Reader 64-bit for enterprises, refer to the Adobe Acrobat Enterprise Administration Guide.
#>

#description: Installs the latest Adobe Acrobat Reader MUI 64-bit with automatic updates disabled. Forces Reader into read-only mode
#execution mode: Combined
#tags: Evergreen, Adobe, Acrobat, PDF
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Adobe\AcrobatReaderDC"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

#region Script logic
#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    [System.String] $Architecture = "x64"
    [System.String] $Language = "MUI"
    Write-LogFile -Message "Using default values for Adobe Acrobat Reader: Architecture = $Architecture, Language = $Language"
}
else {
    $Variables = Get-NerdioVariablesList
    [System.String] $Architecture = $Variables.$AzureRegionName.AdobeAcrobatArchitecture
    [System.String] $Language = $Variables.$AzureRegionName.AdobeAcrobatLanguage
    Write-LogFile -Message "Using secure variables for Adobe Acrobat Reader: Architecture = $Architecture, Language = $Language"
}
#endregion

# Run tasks/install apps
# Enforce settings with GPO: https://www.adobe.com/devnet-docs/acrobatetk/tools/AdminGuide/gpo.html
# https://helpx.adobe.com/au/enterprise/kb/acrobat-64-bit-for-enterprises.html

# Download Reader installer
Write-LogFile -Message "Query Evergreen for Adobe Acrobat Reader DC $Language $Architecture"
$App = Get-EvergreenApp -Name "AdobeAcrobatReaderDC" | `
    Where-Object { $_.Language -eq $Language -and $_.Architecture -eq $Architecture } | `
    Select-Object -First 1
Write-LogFile -Message "Downloading Adobe Acrobat Reader DC version $($App.Version) to $Path"
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

# Install Adobe Acrobat Reader
$LogPath = (Get-LogFile).Path
$LogFile = "$LogPath\AdobeAcrobatReaderDC$($App.Version).log" -replace " ", ""
$Options = "EULA_ACCEPT=YES
        ENABLE_CHROMEEXT=0
        DISABLE_BROWSER_INTEGRATION=1
        ENABLE_OPTIMIZATION=YES
        ADD_THUMBNAILPREVIEW=0
        DISABLEDESKTOPSHORTCUT=1"
$ArgumentList = "-sfx_nu /sALL /rps /l /msi $($Options -replace "\s+", " ") /log $LogFile"
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = $ArgumentList
}
Start-ProcessWithLog @params

#region Acrobat policies: # https://www.adobe.com/devnet-docs/acrobatetk/tools/PrefRef/Windows/FeatureLockDown.html
# Force Reader into read-only mode; Disable Adobe Updater
Write-LogFile -Message "Configuring Adobe Acrobat Reader policies to enforce read-only mode and disable updates"
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bIsSCReducedModeEnforcedEx" /d 1 /t "REG_DWORD" /f'
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bAcroSuppressUpsell" /d 1 /t "REG_DWORD" /f'
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bDisableJavaScript" /d 1 /t "REG_DWORD" /f'
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bToggleDCAppCenter" /d 1 /t "REG_DWORD" /f'
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cIPM" /v "bDontShowMsgWhenViewingDoc" /d 0 /t "REG_DWORD" /f'
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bUpdater" /d 0 /t "REG_DWORD" /f'
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Adobe\Adobe Acrobat\DC\Installer" /v "DisableMaintenance" /d 1 /t "REG_DWORD" /f'
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bToggleShareFeedback" /d 0 /t "REG_DWORD" /f'
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\WOW6432Node\Adobe\Adobe ARM\Legacy\Reader\{AC76BA86-7AD7-1033-7B44-AC0F074E4100}" /v "Mode" /d 0 /t "REG_DWORD" /f'
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bToggleAdobeDocumentServices" /d 1 /t "REG_DWORD" /f'
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bToggleAdobeSign" /d 1 /t "REG_DWORD" /f'
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bToggleDocumentCloud" /d 0 /t "REG_DWORD" /f'
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bToggleWebConnectors" /d 0 /t "REG_DWORD" /f'
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bBoxConnectorEnabled" /d 0 /t "REG_DWORD" /f'
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bDropboxConnectorEnabled" /d 0 /t "REG_DWORD" /f'
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bGoogleDriveConnectorEnabled" /d 0 /t "REG_DWORD" /f'
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bOneDriveConnectorEnabled" /d 0 /t "REG_DWORD" /f'
#endregion

# Disable update tasks - assuming we're installing on a gold image or updates will be managed
Write-LogFile -Message "Disabling Adobe Acrobat Reader update tasks and services"
Get-Service -Name "AdobeARMservice" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
Get-ScheduledTask -TaskName "Adobe Acrobat Update Task*" | Unregister-ScheduledTask -Confirm:$false -ErrorAction "SilentlyContinue"

# Delete public desktop shortcut
Write-LogFile -Message "Removing public desktop shortcut for Adobe Acrobat Reader"
$Shortcuts = @("$Env:Public\Desktop\Adobe Acrobat.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "SilentlyContinue"
#endregion
