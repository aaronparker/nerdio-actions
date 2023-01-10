<#
    .SYNOPSIS
        Use Pester and Evergreen to validate installed apps.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This OK for the tests files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
[CmdletBinding()]
param()

BeforeDiscovery {

    # Get the working directory
    if ([System.String]::IsNullOrWhiteSpace($env:GITHUB_WORKSPACE)) {
        $Path = [System.IO.Path]::Combine($PWD.Path, "scripts", "uninstall")
    }
    else {
        $Path = [System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "scripts", "uninstall")
    }

    # Get the scripts to test
    $Scripts = Get-ChildItem -Path $Path -Include "*.ps1" -Recurse
}

Describe -Name "Uninstall scripts" -ForEach $Scripts {
    Context "The script <_.Name> runs successfully" {
        It "Should not throw during execution" {
            { & $_.FullName } | Should -Not -Throw
        }
    }
}
