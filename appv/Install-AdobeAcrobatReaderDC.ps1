#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Temp"
[System.String] $Architecture = "x64"
[System.String] $Language = "MUI"

New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Run tasks/install apps
# Enforce settings with GPO: https://www.adobe.com/devnet-docs/acrobatetk/tools/AdminGuide/gpo.html
# https://helpx.adobe.com/au/enterprise/kb/acrobat-64-bit-for-enterprises.html

# Download Reader installer
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "AdobeAcrobatReaderDC" | `
    Where-Object { $_.Language -eq $Language -and $_.Architecture -eq $Architecture } | `
    Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

# Install Adobe Acrobat Reader
$Options = "INSTALL_DIR=`"$Env:ProgramFiles\Adobe\Acrobat DC`"
        EULA_ACCEPT=YES
        ENABLE_CHROMEEXT=0
        DISABLE_BROWSER_INTEGRATION=1
        ENABLE_OPTIMIZATION=YES
        ADD_THUMBNAILPREVIEW=0
        DISABLEDESKTOPSHORTCUT=1"
$ArgumentList = "-sfx_nu /sALL /rps /l /msi $($Options -replace "\s+", " ")"
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = $ArgumentList
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params

#region Acrobat policies: # https://www.adobe.com/devnet-docs/acrobatetk/tools/PrefRef/Windows/FeatureLockDown.html
# Force Reader into read-only mode
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bIsSCReducedModeEnforcedEx" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bAcroSuppressUpsell" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bDisableJavaScript" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bToggleDCAppCenter" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cIPM" /v "bDontShowMsgWhenViewingDoc" /d 0 /t "REG_DWORD" /f | Out-Null

# AppV optimisations
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cIPM" /v "bToggleNotifications" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\WOW6432Node\Adobe\Adobe Acrobat\DC\Installer" /v "DisableMaintainence" /d 1 /t "REG_DWORD" /f | Out-Null

# Disable Adobe Updater
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bUpdater" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Adobe\Adobe Acrobat\DC\Installer" /v "DisableMaintenance" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bToggleShareFeedback" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\WOW6432Node\Adobe\Adobe ARM\Legacy\Reader\{AC76BA86-7AD7-1033-7B44-AC0F074E4100}" /v "Mode" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bToggleAdobeDocumentServices" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bToggleAdobeSign" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bToggleDocumentCloud" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bToggleWebConnectors" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bBoxConnectorEnabled" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bDropboxConnectorEnabled" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bGoogleDriveConnectorEnabled" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bOneDriveConnectorEnabled" /d 0 /t "REG_DWORD" /f | Out-Null
#endregion

# Disable update tasks - assuming we're installing on a gold image or updates will be managed
Get-Service -Name "AdobeARMservice" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
Get-ScheduledTask -TaskName "Adobe Acrobat Update Task*" | Unregister-ScheduledTask -Confirm:$false -ErrorAction "SilentlyContinue"

# Delete public desktop shortcut
$Shortcuts = @("$Env:Public\Desktop\Adobe Acrobat.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "SilentlyContinue"
#endregion
