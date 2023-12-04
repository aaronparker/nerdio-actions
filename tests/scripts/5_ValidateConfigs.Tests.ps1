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

Describe "Microsoft Edge configuration" {
    Context "Application preferences" {
        It "Should have written the correct content to master_preferences" {
            (Get-Content -Path "${Env:ProgramFiles(x86)}\Microsoft\Edge\Application\master_preferences" | ConvertFrom-Json).homepage | Should -BeExactly "https://www.microsoft365.com"
        }
    }
}

Describe "Google Chrome configuration" {
    Context "Application preferences" {
        It "Should have written the correct content to master_preferences" {
            (Get-Content -Path "$Env:ProgramFiles\Google\Chrome\Application\master_preferences" | ConvertFrom-Json).homepage | Should -BeExactly "https://www.office.com"
        }
    }
}
