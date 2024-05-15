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
    $SupportScripts = Get-ChildItem -Path $Path -Include "0*.ps1" -Recurse -Exclude "012_WindowsUpdate.ps1"
    $DependencyScripts = Get-ChildItem -Path $Path -Include "1*.ps1" -Recurse
    $MicrosoftAppsScripts = Get-ChildItem -Path $Path -Include "2*.ps1" -Recurse
    $3rdPartyScripts = Get-ChildItem -Path $Path -Include "4*.ps1" -Recurse
    $CleanupScripts = Get-ChildItem -Path $Path -Include "9*.ps1" -Recurse

    # Get scripts to run a 2nd time
    $2ndRunScripts = Get-ChildItem -Path $Path -Include "201_MicrosoftTeams.ps1" -Recurse
}

Describe "Run application image scripts with required modules installed" {
    Context "Support scripts run successfully" {
        It "Should not throw during execution: <_.Name>" -ForEach $SupportScripts {
            { & $_.FullName } | Should -Not -Throw
        }
    }

    Context "The dependency script runs successfully" {
        It "Should not throw during execution: <_.Name>" -ForEach $DependencyScripts {
            { & $_.FullName } | Should -Not -Throw
        }
    }

    Context "The Microsoft apps script runs successfully" {
        It "Should not throw during execution: <_.Name>" -ForEach $MicrosoftAppsScripts {
            { & $_.FullName } | Should -Not -Throw
        }
    }

    Context "The 3rd party apps script runs successfully" {
        It "Should not throw during execution: <_.Name>" -ForEach $3rdPartyScripts {
            { & $_.FullName } | Should -Not -Throw
        }
    }

    Context "The clean up script runs successfully" {
        It "Should not throw during execution: <_.Name>" -ForEach $CleanupScripts {
            { & $_.FullName } | Should -Not -Throw
        }
    }
}

Describe "Run application image scripts that need a second run" {
    It "Should not throw during execution: <_.Name>" -ForEach $2ndRunScripts {
        { & $_.FullName } | Should -Not -Throw
    }
}
