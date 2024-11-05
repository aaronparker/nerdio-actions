<#
.SYNOPSIS
Installs Windows language support and sets language/regional settings.

.DESCRIPTION
This script installs Windows language support and sets the language and regional settings on a Windows machine.
It also enables WinRM and PS Remoting to fix an issue with VM deployment using non en-US language packs.

.PARAMETER SecureVars
Use Secure variables in Nerdio Manager to pass a JSON file with the variables list.

.EXAMPLE
.\013_RegionLanguage.ps1

This example runs the script and installs the language pack and sets the regional settings based on the specified variables.

.NOTES
- This script requires the LanguagePackManagement module to be installed.
- The script enables the WinRM rule as a workaround for VM provisioning DSC failure with "Unable to check the status of the firewall".
- The script sets the locale, time zone, culture, system locale, UI language, user language list, and home location based on the specified language and time zone.
#>

#description: Installs Windows language support and sets language/regional settings. Note that this script enables WinRM and PS Remoting to fix an issue with VM deployment using non en-US language packs
#execution mode: Combined
#tags: Language, Image

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    [System.String] $Language = "en-AU"
    [System.String] $TimeZone = "AUS Eastern Standard Time"
}
else {
    $ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $params = @{
        Uri             = $SecureVars.VariablesList
        UseBasicParsing = $true
        ErrorAction     = "Stop"
    }
    $Variables = Invoke-RestMethod @params
    [System.String] $Language = $Variables.$AzureRegionName.Language
    [System.String] $TimeZone = $Variables.$AzureRegionName.TimeZone
}
#endregion

#region Only run if the LanguagePackManagement module is installed
# Works for Windows 10 22H2, Windows 11, Windows Server 2025
if (Get-Module -Name "LanguagePackManagement" -ListAvailable) {

    # Disable Language Pack Cleanup
    # https://learn.microsoft.com/en-us/azure/virtual-desktop/windows-11-language-packs
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -TaskName "Pre-staged app cleanup"
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\MUI\" -TaskName "LPRemove"
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\LanguageComponentsInstaller" -TaskName "Uninstallation"
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Control Panel\International" /v "BlockCleanupOfUnusedPreinstalledLangPacks" /t REG_DWORD /d 1 /f *> $null

    # Ensure no Windows Update settings will block the installation of language packs
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DoNotConnectToWindowsUpdateInternetLocations" /d 0 /t REG_DWORD /f
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "UseWUServer" /d 0 /t REG_DWORD /f

    # Enable the WinRM rule as a workaround for VM provisioning DSC failure with: "Unable to check the status of the firewall"
    # https://github.com/Azure/RDS-Templates/issues/435
    # https://qiita.com/fujinon1109/items/440c614338fe2535b09e
    Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory "Private"
    Get-NetFirewallRule -DisplayGroup "Windows Remote Management" | Enable-NetFirewallRule
    Enable-PSRemoting -Force
    Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory "Public"

    # Install the language pack
    $params = @{
        Language        = $Language
        CopyToSettings  = $true
        ExcludeFeatures = $false
    }
    Install-Language @params
}
#endregion

# $LanguageList = Get-WinUserLanguageList
# $LanguageList.Add("es-es")
# $LanguageList.Add("fr-fr")
# $LanguageList.Add("zh-cn")
# Set-WinUserLanguageList $LanguageList -force

#region Set the locale
Import-Module -Name "International"
Set-TimeZone -Name $TimeZone
Set-Culture -CultureInfo $Language
Set-WinSystemLocale -SystemLocale $Language
Set-WinUILanguageOverride -Language $Language
Set-WinUserLanguageList -LanguageList $Language -Force
$RegionInfo = New-Object -TypeName "System.Globalization.RegionInfo" -ArgumentList $Language
Set-WinHomeLocation -GeoId $RegionInfo.GeoId
if (Get-Command -Name "Set-SystemPreferredUILanguage" -ErrorAction "SilentlyContinue") {
    Set-SystemPreferredUILanguage -Language $Language
}
#endregion

# Enable LanguageComponentsInstaller after language packs are installed
# Enable-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\Installation"
# Enable-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\ReconcileLanguageResources"
