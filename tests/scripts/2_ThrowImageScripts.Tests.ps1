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
    $Path = "$Path\scripts\image"
    $DependencyScripts = Get-ChildItem -Path $Path -Include "1*.ps1" -Recurse
    $MicrosoftAppsScripts = Get-ChildItem -Path $Path -Include "2*.ps1" -Recurse
    $3rdPartyScripts = Get-ChildItem -Path $Path -Include "4*.ps1" -Recurse
}

Describe "Run application image scripts without required modules installed" {
    Context "The dependency script throws an error" {
        It "Should throw during execution: <_.Name>" -ForEach $DependencyScripts {
            { & $_.FullName } | Should -Throw
        }
    }

    Context "The Microsoft apps script throws an error" {
        It "Should throw during execution: <_.Name>" -ForEach $MicrosoftAppsScripts {
            { & $_.FullName } | Should -Throw
        }
    }

    Context "The 3rd party apps script throws an error" {
        It "Should throw during execution: <_.Name>" -ForEach $3rdPartyScripts {
            { & $_.FullName } | Should -Throw
        }
    }
}
