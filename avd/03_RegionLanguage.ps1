#description: Installs Windows language support. Set language/regional settings
#execution mode: Combined
#tags: Language

#region Use Secure variables in Nerdio Manager to pass a system language
if ($null -eq $SecureVars.OSLanguage) {
    [System.String] $Language = "en-AU"
}
else {
    [System.String] $Language = $SecureVars.OSLanguage
}
#endregion

# Only run if the LanguagePackManagement module is installed
if (Get-Module -Name "LanguagePackManagement" -ListAvailable) {
    try {
        $params = @{
            Language        = $Language
            CopyToSettings  = $true
            ExcludeFeatures = $false
        }
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
        Set-SystemPreferredUILanguage @params
    }
    catch {
        throw $_.Exception.Message
    }
}

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
    Set-WinSystemLocale -SystemLocale $Language
    Set-WinHomeLocation -GeoId $GeoId.$Language
}
catch {
    throw $_.Exception.Message
}
