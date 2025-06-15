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

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    Write-LogFile -Message "Using default language and time zone settings."
    [System.String] $Language = "en-AU"
    [System.String] $TimeZone = "AUS Eastern Standard Time"
    Write-LogFile -Message "Using default language: $Language and time zone: $TimeZone"
}
else {
    $Variables = Get-NerdioVariablesList
    [System.String] $Language = $Variables.$AzureRegionName.Language
    [System.String] $TimeZone = $Variables.$AzureRegionName.TimeZone
    Write-LogFile -Message "Using language: $Language and time zone: $TimeZone"
}
#endregion

#region Only run if the LanguagePackManagement module is installed
# Works for Windows 10 22H2, Windows 11, Windows Server 2025
if (Get-Module -Name "LanguagePackManagement" -ListAvailable) {
    Write-LogFile -Message "LanguagePackManagement module found. Proceeding with language pack installation."

    # Disable Language Pack Cleanup
    # https://learn.microsoft.com/en-us/azure/virtual-desktop/windows-11-language-packs
    Write-LogFile -Message "Disabling Language Pack Cleanup tasks."
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -TaskName "Pre-staged app cleanup"
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\MUI\" -TaskName "LPRemove"
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\LanguageComponentsInstaller" -TaskName "Uninstallation"
    Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add "HKLM\SOFTWARE\Policies\Microsoft\Control Panel\International" /v BlockCleanupOfUnusedPreinstalledLangPacks /t REG_DWORD /d 1 /f'

    # Ensure no Windows Update settings will block the installation of language packs
    Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList 'add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v DoNotConnectToWindowsUpdateInternetLocations /d 0 /t REG_DWORD /f'
    Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "delete HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /f"

    # Enable the WinRM rule as a workaround for VM provisioning DSC failure with: "Unable to check the status of the firewall"
    # https://github.com/Azure/RDS-Templates/issues/435
    # https://qiita.com/fujinon1109/items/440c614338fe2535b09e
    Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -eq "Public" } | ForEach-Object {
        Write-LogFile -Message "Setting network category to Private for: $($_.Name)"
        Set-NetConnectionProfile -Name $_.Name -NetworkCategory "Private"
    }
    Write-LogFile -Message "Enabling WinRM firewall rules."
    Get-NetFirewallRule -DisplayGroup "Windows Remote Management" | Enable-NetFirewallRule
    Write-LogFile -Message "Enabling PS Remoting."
    Enable-PSRemoting -Force
    Write-LogFile -Message "Setting network category to Public."
    Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory "Public"

    # Install the language pack
    Write-LogFile -Message "Installing language pack: $Language"
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
Write-LogFile -Message "Setting time zone to: $TimeZone"
Set-TimeZone -Name $TimeZone
Write-LogFile -Message "Setting locale to: $Language"
Set-Culture -CultureInfo $Language
Set-WinSystemLocale -SystemLocale $Language
Set-WinUILanguageOverride -Language $Language
Set-WinUserLanguageList -LanguageList $Language -Force
$RegionInfo = New-Object -TypeName "System.Globalization.RegionInfo" -ArgumentList $Language
Set-WinHomeLocation -GeoId $RegionInfo.GeoId
if (Get-Command -Name "Set-SystemPreferredUILanguage" -ErrorAction "SilentlyContinue") {
    Write-LogFile -Message "Setting system preferred UI language to: $Language"
    Set-SystemPreferredUILanguage -Language $Language
}
#endregion

# Enable LanguageComponentsInstaller after language packs are installed
# Enable-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\Installation"
# Enable-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\ReconcileLanguageResources"
