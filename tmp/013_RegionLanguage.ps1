#description: Installs Windows language support and sets language/regional settings. Note that this script enables WinRM and PS Remoting to fix an issue with VM deployment using non en-US language packs
#execution mode: Combined
#tags: Language, Image

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    [System.String] $Language = "en-AU"
    [System.String] $TimeZone = "AUS Eastern Standard Time"
}
else {
    try {
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
    catch {
        throw $_
    }
}
#endregion

#region Enable the WinRM rule as a workaround for VM provisioning DSC failure with: "Unable to check the status of the firewall"
# https://github.com/Azure/RDS-Templates/issues/435
# https://qiita.com/fujinon1109/items/440c614338fe2535b09e
Write-Information -MessageData "Enable-NetFirewallRule 'Windows Remote Management'" -InformationAction "Continue"
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory "Private"
Get-NetFirewallRule -DisplayGroup "Windows Remote Management" | Enable-NetFirewallRule
Enable-PSRemoting -Force
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory "Public"
#endregion

#region Only run if the LanguagePackManagement module is installed
if (Get-Module -Name "LanguagePackManagement" -ListAvailable) {
    try {
        $params = @{
            Language        = $Language
            CopyToSettings  = $true
            ExcludeFeatures = $false
        }
        Write-Information -MessageData ":: Install language pack for: $Language" -InformationAction "Continue"
        Install-Language @params
    }
    catch {
        throw $_
    }
}
#endregion

# $LanguageList = Get-WinUserLanguageList
# $LanguageList.Add("es-es")
# $LanguageList.Add("fr-fr")
# $LanguageList.Add("zh-cn")
# Set-WinUserLanguageList $LanguageList -force

#region Set the locale
try {
    Write-Information -MessageData ":: Set locale to: $Language" -InformationAction "Continue"
    $RegionInfo = New-Object -TypeName "System.Globalization.RegionInfo" -ArgumentList $Language

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
}
catch {
    throw $_
}
#endregion
