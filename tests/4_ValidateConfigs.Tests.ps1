<#
    .SYNOPSIS
        Use Pester to validate application files and services etc.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This OK for the tests files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
[CmdletBinding()]
param()

BeforeDiscovery {
}

Describe -Name "Microsoft Edge" {
    Context "Application preferences" {
        It "Should have written the correct content to master_preferences" {
            (Get-Content -Path "${Env:ProgramFiles(x86)}\Microsoft\Edge\Application\master_preferences" | ConvertFrom-Json).homepage | Should -BeExactly "https://www.office.com"
        }
    }
}

Describe -Name "Google Chrome" {
    Context "Application preferences" {
        It "Should have written the correct content to master_preferences" {
            (Get-Content -Path "$Env:ProgramFiles\Google\Chrome\Application\master_preferences" | ConvertFrom-Json).homepage | Should -BeExactly "https://www.office.com"
        }
    }
}
