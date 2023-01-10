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

Describe -Name "Dependency scripts without required modules" -ForEach $DependencyScripts {
    Context "The script <_.Name> throws without required modules installed" {
        It "Should throw during execution" {
            { & $_.FullName } | Should -Throw
        }
    }
}

Describe -Name "Microsoft apps scripts without required modules" -ForEach $MicrosoftAppsScripts {
    Context "The script <_.Name> throws without required modules installed" {
        It "Should throw during execution" {
            { & $_.FullName } | Should -Throw
        }
    }
}

Describe -Name "3rd party apps scripts without required modules" -ForEach $3rdPartyScripts {
    Context "The script <_.Name> throws without required modules installed" {
        It "Should throw during execution" {
            { & $_.FullName } | Should -Throw
        }
    }
}
