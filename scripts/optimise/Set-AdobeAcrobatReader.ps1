#description: Optimise Adobe Acrobat Reader - disable updates, force Reader mode
#execution mode: Combined
#tags: Adobe, Acrobat, PDF, Optimise

# https://helpx.adobe.com/au/enterprise/kb/acrobat-64-bit-for-enterprises.html

# Force Reader into read-only mode
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bIsSCReducedModeEnforcedEx" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cIPM" /v "bDontShowMsgWhenViewingDoc" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bAcroSuppressUpsell" /d 1 /t "REG_DWORD" /f | Out-Null

# Disable Adobe Updater
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bUpdater" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\WOW6432Node\Adobe\Adobe ARM\Legacy\Reader\{AC76BA86-7AD7-1033-7B44-AC0F074E4100}" /v "Mode" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Adobe\Adobe Acrobat\DC\Installer" /v "DisableMaintenance" /d 1 /t "REG_DWORD" /f | Out-Null

# Disable update tasks - assuming we're installing on a gold image or updates will be managed
Get-Service -Name "AdobeARMservice" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
Get-ScheduledTask -TaskName "Adobe Acrobat Update Task*" | Unregister-ScheduledTask -Confirm:$false -ErrorAction "SilentlyContinue"

# Delete public desktop shortcut
$Shortcuts = @("$Env:Public\Desktop\Adobe Acrobat.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "SilentlyContinue"
