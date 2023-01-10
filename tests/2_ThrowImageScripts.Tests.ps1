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
        $Path = [System.IO.Path]::Combine($PWD.Path, "scripts", "image")
    }
    else {
        $Path = [System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "scripts", "image")
    }

    # Get the scripts to test
    $DependencyScripts = Get-ChildItem -Path $Path -Include "1*.ps1" -Recurse
    $MicrosoftAppsScripts = Get-ChildItem -Path $Path -Include "2*.ps1" -Recurse
    $3rdPartyScripts = Get-ChildItem -Path $Path -Include "4*.ps1" -Recurse
}

Describe "Run application image scripts without required modules installed" {
    Context "The dependency script <_.Name> throws an error" -ForEach $DependencyScripts {
        It "Should throw during execution" {
            { & $_.FullName } | Should -Throw
        }
    }

    Context "The Microsoft apps script <_.Name> throws an error" -ForEach $MicrosoftAppsScripts {
        It "Should throw during execution" {
            { & $_.FullName } | Should -Throw
        }
    }

    Context "The 3rd party apps script <_.Name> throws an error" -ForEach $3rdPartyScripts {
        It "Should throw during execution" {
            { & $_.FullName } | Should -Throw
        }
    }
}
