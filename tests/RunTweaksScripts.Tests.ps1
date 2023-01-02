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
    if ([System.String]::IsNullOrWhiteSpace($env:GITHUB_WORKSPACE)) {
        $Path = [System.IO.Path]::Combine($PWD.Path, "scripts", "tweaks")
    }
    else {
        $Path = [System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "scripts", "tweaks")
    }

    # Get the scripts to test
    $Scripts = Get-ChildItem -Path $Path -Include "*.ps1" -Recurse -Exclude "Enable-SysprepCryptoSysPrep_Specialize.ps1"
}

Describe -Name "Tweaks scripts" -ForEach $Scripts {
    Context "The script <_.Name> runs successfully" {
        It "Should not throw during execution" {
            Write-Host "Running: $($_.Name)"
            & $_.FullName
        }
    }
}
