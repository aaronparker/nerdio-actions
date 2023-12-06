<#
    .SYNOPSIS
        Use Pester to validate tweaks scripts
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This OK for the tests files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
[CmdletBinding()]
param()

BeforeDiscovery {

    # Get the working directory
    if ([System.String]::IsNullOrWhiteSpace($Env:GITHUB_WORKSPACE)) {
        $Path = [System.IO.Path]::Combine($PWD.Path, "scripts", "tweaks")
    }
    else {
        $Path = [System.IO.Path]::Combine($Env:GITHUB_WORKSPACE, "scripts", "tweaks")
    }

    # Get the scripts to test
    $Scripts = Get-ChildItem -Path $Path -Include "*.ps1" -Recurse -Exclude "Enable-SysprepCryptoSysPrep_Specialize.ps1", "Install-FSLogixAppMaskingRuleset.ps1", "Set-FSLogixStorageAccount.ps1"
}

Describe "Run tweaks scripts" {
    Context "The script runs successfully" {
        It "Should not throw: <_.Name>" -ForEach $Scripts {
            { & $_.FullName } | Should -Not -Throw
        }
    }
}
