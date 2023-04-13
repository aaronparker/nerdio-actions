#description: Installs the latest Adobe Acrobat Reader MUI 64-bit with automatic updates disabled. Forces Reader into read-only mode
#execution mode: Combined
#tags: Evergreen, Adobe, Acrobat, PDF
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Adobe\AcrobatReaderDC"
[System.String] $Architecture = "x64"
[System.String] $Language = "MUI"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Run tasks/install apps
# Enforce settings with GPO: https://www.adobe.com/devnet-docs/acrobatetk/tools/AdminGuide/gpo.html
# https://helpx.adobe.com/au/enterprise/kb/acrobat-64-bit-for-enterprises.html

try {
    # Download Reader installer
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "AdobeAcrobatReaderDC" | `
        Where-Object { $_.Language -eq $Language -and $_.Architecture -eq $Architecture } | `
        Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}

try {
    # Install Adobe Acrobat Reader
    Write-Information -MessageData ":: Install Adobe Acrobat Reader DC" -InformationAction "Continue"
    $LogFile = "$Env:ProgramData\Evergreen\Logs\AdobeAcrobatReaderDC$($App.Version).log" -replace " ", ""
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
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
}
catch {
    throw $_.Exception.Message
}

try {
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
}
catch {
    throw $_.Exception.Message
}
#endregion
