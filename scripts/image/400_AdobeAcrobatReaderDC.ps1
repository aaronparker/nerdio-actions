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

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    [System.String] $Architecture = "x64"
    [System.String] $Language = "MUI"
}
else {

    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $params = @{
        Uri             = $SecureVars.VariablesList
        UseBasicParsing = $true
        ErrorAction     = "Stop"
    }
    $Variables = Invoke-RestMethod @params
    [System.String] $Architecture = $Variables.$AzureRegionName.AdobeAcrobatArchitecture
    [System.String] $Language = $Variables.$AzureRegionName.AdobeAcrobatLanguage
}
#endregion

# Run tasks/install apps
# Enforce settings with GPO: https://www.adobe.com/devnet-docs/acrobatetk/tools/AdminGuide/gpo.html
# https://helpx.adobe.com/au/enterprise/kb/acrobat-64-bit-for-enterprises.html

# Download Reader installer
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "AdobeAcrobatReaderDC" | `
    Where-Object { $_.Language -eq $Language -and $_.Architecture -eq $Architecture } | `
    Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

# Install Adobe Acrobat Reader
$LogFile = "$Env:ProgramData\Nerdio\Logs\AdobeAcrobatReaderDC$($App.Version).log" -replace " ", ""
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
    ErrorAction  = "Stop"
}
Start-Process @params

# Force Reader into read-only mode
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bIsSCReducedModeEnforcedEx" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v "bAcroSuppressUpsell" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cIPM" /v "bDontShowMsgWhenViewingDoc" /d 0 /t "REG_DWORD" /f | Out-Null

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
#endregion
