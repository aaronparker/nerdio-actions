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
    $SupportScripts = Get-ChildItem -Path $Path -Include "0*.ps1" -Recurse -Exclude "012_WindowsUpdate.ps1"
    $DependencyScripts = Get-ChildItem -Path $Path -Include "1*.ps1" -Recurse -Exclude "101_Avd-Agents.ps1"
    $MicrosoftAppsScripts = Get-ChildItem -Path $Path -Include "2*.ps1" -Recurse
    $3rdPartyScripts = Get-ChildItem -Path $Path -Include "4*.ps1" -Recurse #-Exclude "401_FoxitPDReader.ps1"
    $CleanupScripts = Get-ChildItem -Path $Path -Include "9*.ps1" -Recurse
}

Describe "Run application image scripts with required modules installed" {
    Context "The support script <_.Name> runs successfully" -ForEach $SupportScripts {
        It "Should not throw" {
            { & $_.FullName } | Should -Not -Throw
        }
    }

    Context "The dependency script <_.Name> runs successfully" -ForEach $DependencyScripts {
        It "Should not throw" {
            { & $_.FullName } | Should -Not -Throw
        }
    }

    Context "The Microsoft apps script <_.Name> runs successfully" -ForEach $MicrosoftAppsScripts {
        It "Should not throw" {
            { & $_.FullName } | Should -Not -Throw
        }
    }

    Context "The 3rd party apps script <_.Name> runs successfully" -ForEach $3rdPartyScripts {
        It "Should not throw" {
            { & $_.FullName } | Should -Not -Throw
        }
    }

    Context "The clean-up script <_.Name> runs successfully" -ForEach $CleanupScripts {
        It "Should not throw" {
            { & $_.FullName } | Should -Not -Throw
        }
    }
}
