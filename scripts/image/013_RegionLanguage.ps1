#description: Installs Windows language support and sets language/regional settings
#execution mode: Combined
#tags: Language, Image

#region Use Secure variables in Nerdio Manager to pass a system language
if ($null -eq $SecureVars.OSLanguage) {
    [System.String] $Language = "en-AU"
}
else {
    [System.String] $Language = $SecureVars.OSLanguage
}
#endregion

#region Enable the WinRM rule as a workaround for VM provisioning DSC failure with: "Unable to check the status of the firewall"
# https://github.com/Azure/RDS-Templates/issues/435
# https://qiita.com/fujinon1109/items/440c614338fe2535b09e
Write-Information -MessageData "Enable-NetFirewallRule 'Windows Remote Management'" -InformationAction "Continue"
Get-NetFirewallRule -DisplayGroup "Windows Remote Management" | Enable-NetFirewallRule
Enable-PSRemoting -Force
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
        Install-Language @params | Out-Null
    }
    catch {
        throw $_.Exception.Message
    }

    try {
        $params = @{
            Language = $Language
            PassThru = $false
        }
        Write-Information -MessageData ":: Set system UI language to: $Language" -InformationAction "Continue"
        Set-SystemPreferredUILanguage @params
    }
    catch {
        throw $_.Exception.Message
    }
}
#endregion

#region Set the locale
try {
    $GeoId = @{
        "en-US" = 244
        "en-GB" = 242
        "en-AU" = 12
        "en-NZ" = 183
        "en-CA" = 39
        "ph-PH" = 201
    }
    Import-Module -Name "International"
    Write-Information -MessageData ":: Set locale to: $Language" -InformationAction "Continue"
    Set-WinSystemLocale -SystemLocale $Language
    Set-WinHomeLocation -GeoId $GeoId.$Language
}
catch {
    throw $_.Exception.Message
}
#endregion
