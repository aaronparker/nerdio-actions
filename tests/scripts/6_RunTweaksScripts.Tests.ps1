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
    if (!([System.String]::IsNullOrWhiteSpace($Env:GITHUB_WORKSPACE))) {
        $Path = $Env:GITHUB_WORKSPACE
    }
    elseif (!([System.String]::IsNullOrWhiteSpace($Env:BUILD_SOURCESDIRECTORY))) {
        $Path = $Env:BUILD_SOURCESDIRECTORY
    }
    else {
        $Path = $PWD.Path
    }

    # Get the scripts to test
    $Path = "$Path\scripts\tweaks"
    $Exclude = "Invoke-DefenderFullScan.ps1", "Enable-SysprepCryptoSysPrep_Specialize.ps1", "Install-FSLogixAppMaskingRuleset.ps1", "Set-FSLogixStorageAccount.ps1"
    $Scripts = Get-ChildItem -Path $Path -Include "*.ps1" -Recurse -Exclude $Exclude
}

Describe "Run tweaks scripts" {
    Context "The script runs successfully" {
        It "Should not throw: <_.Name>" -ForEach $Scripts {
            { & $_.FullName } | Should -Not -Throw
        }
    }
}
