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
    $Scripts = Get-ChildItem -Path $Path -Include "*.ps1" -Recurse -Exclude @("Uninstall-NotepadPlusPlus.ps1")
    $Scripts2 = Get-ChildItem -Path $Path -Include "*.ps1" -Recurse -Exclude @("Uninstall-7ZipZS.ps1", "Uninstall-MicrosoftNET.ps1", "Uninstall-NotepadPlusPlus.ps1", "Uninstall-MicrosoftOneDrive.ps1")
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
