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

Describe "Uninstall scripts with software installed" {
    Context "The script runs successfully with software installed"  {
        It "Should not throw: <_.Name>" -ForEach $Scripts {
            { & $_.FullName } | Should -Not -Throw
        }
    }
}

Describe "Uninstall scripts without software installed" {
    Context "The script runs successfully with no software installed"  {
        It "Should not throw: <_.Name>" -ForEach $Scripts2 {
            { & $_.FullName } | Should -Not -Throw
        }
    }
}
