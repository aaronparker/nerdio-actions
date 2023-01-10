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
    $Scripts2 = Get-ChildItem -Path $Path -Include "*.ps1" -Recurse -Exclude @("Uninstall-7ZipZS.ps1", "Uninstall-MicrosoftNET.ps1")
}

Describe -Name "Uninstall scripts with software installed" -ForEach $Scripts {
    Context "The script <_.Name> runs successfully" {
        It "Should not throw when uninstalling software" {
            { & $_.FullName } | Should -Not -Throw
        }
    }
}

Describe -Name "Uninstall scripts without software installed" -ForEach $Scripts2 {
    Context "The script <_.Name> runs successfully" {
        It "Should not throw with no software installed" {
            { & $_.FullName } | Should -Not -Throw
        }
    }
}
