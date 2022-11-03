#description: Installs Windows language support
#execution mode: Combined
#tags: Language
<#
    .SYNOPSIS
        Set language/regional settings.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $Language = "en-AU"
)

try {
    $params = @{
        Language        = $Language
        CopyToSettings  = $True
        ExcludeFeatures = $False
    }
    Write-Verbose -Message "Install language: $Language."
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
    Write-Verbose -Message "Set system language: $Language."
    if ($PSCmdlet.ShouldProcess($Language, "Set-SystemPreferredUILanguage")) {
        Set-SystemPreferredUILanguage @params
    }
}
catch {
    throw $_
}
