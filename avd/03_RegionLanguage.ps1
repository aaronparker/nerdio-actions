#description: Installs Windows language support. Set language/regional settings
#execution mode: Combined
#tags: Language
[System.String] $Language = "en-AU"

try {
    $params = @{
        Language        = $Language
        CopyToSettings  = $True
        ExcludeFeatures = $False
    }
    if ($PSCmdlet.ShouldProcess($Language, "Install-Language")) {
        Install-Language @params | Out-Null
    }
}
catch {
    throw $_
}

try {
    $params = @{
        Language = $Language
        PassThru = $False
    }
    if ($PSCmdlet.ShouldProcess($Language, "Set-SystemPreferredUILanguage")) {
        Set-SystemPreferredUILanguage @params
    }
}
catch {
    throw $_
}
