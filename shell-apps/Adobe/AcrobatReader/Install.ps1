$Context.Log("Installing Adobe Acrobat Reader DC")
$Options = "EULA_ACCEPT=YES
        ENABLE_CHROMEEXT=0
        DISABLE_BROWSER_INTEGRATION=1
        ENABLE_OPTIMIZATION=YES
        ADD_THUMBNAILPREVIEW=0
        DISABLEDESKTOPSHORTCUT=1"
$ArgumentList = "-sfx_nu /sALL /rps /l /msi $($Options -replace "\s+", " ")"
$params = @{
    FilePath     = $Context.GetAttachedBinary()
    ArgumentList = $ArgumentList
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
Start-Process @params
$Context.Log("Install complete")

#region Acrobat policies: # https://www.adobe.com/devnet-docs/acrobatetk/tools/PrefRef/Windows/FeatureLockDown.html
# Force Reader into read-only mode; Disable Adobe Updater
$Context.Log("Configuring Adobe Acrobat Reader policies to enforce read-only mode and disable updates")
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bIsSCReducedModeEnforcedEx" /d 1 /t "REG_DWORD" /f'
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bAcroSuppressUpsell" /d 1 /t "REG_DWORD" /f'
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bDisableJavaScript" /d 1 /t "REG_DWORD" /f'
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bToggleDCAppCenter" /d 1 /t "REG_DWORD" /f'
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cIPM" /v "bDontShowMsgWhenViewingDoc" /d 0 /t "REG_DWORD" /f'
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bUpdater" /d 0 /t "REG_DWORD" /f'
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Adobe\Adobe Acrobat\DC\Installer" /v "DisableMaintenance" /d 1 /t "REG_DWORD" /f'
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bToggleShareFeedback" /d 0 /t "REG_DWORD" /f'
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\WOW6432Node\Adobe\Adobe ARM\Legacy\Reader\{AC76BA86-7AD7-1033-7B44-AC0F074E4100}" /v "Mode" /d 0 /t "REG_DWORD" /f'
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bToggleAdobeDocumentServices" /d 1 /t "REG_DWORD" /f'
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bToggleAdobeSign" /d 1 /t "REG_DWORD" /f'
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bToggleDocumentCloud" /d 0 /t "REG_DWORD" /f'
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bToggleWebConnectors" /d 0 /t "REG_DWORD" /f'
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bBoxConnectorEnabled" /d 0 /t "REG_DWORD" /f'
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bDropboxConnectorEnabled" /d 0 /t "REG_DWORD" /f'
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bGoogleDriveConnectorEnabled" /d 0 /t "REG_DWORD" /f'
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /v "bOneDriveConnectorEnabled" /d 0 /t "REG_DWORD" /f'
#endregion

# Disable update tasks - assuming we're installing on a gold image or updates will be managed
$Context.Log("Disabling Adobe Acrobat Reader update tasks and services")
Get-Service -Name "AdobeARMservice" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
Get-ScheduledTask -TaskName "Adobe Acrobat Update Task*" | Unregister-ScheduledTask -Confirm:$false -ErrorAction "SilentlyContinue"

# Delete public desktop shortcut
$Context.Log("Removing public desktop shortcut for Adobe Acrobat Reader")
$Shortcuts = @("$Env:Public\Desktop\Adobe Acrobat.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "SilentlyContinue"
