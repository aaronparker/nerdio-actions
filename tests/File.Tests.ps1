<#
    .SYNOPSIS
        Use Pester to validate application files
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
[CmdletBinding()]
param()

BeforeDiscovery {

    # Get the list of software to test
    if ([System.String]::IsNullOrWhiteSpace($env:GITHUB_WORKSPACE)) {
        $Path = $PWD.Path
    }
    else {
        $Path = $env:GITHUB_WORKSPACE
    }
}

Describe -Name "Microsoft Edge" {
    Context "Application preferences" {
        It "Should have written master_preferences" {
            "${Env:ProgramFiles(x86)}\Microsoft\Edge\Application\master_preferences" | Should -Exist
        }
    }
}

Describe -Name "Google Chrome" {
    Context "Application preferences" {
        It "Should have written master_preferences" {
            "$Env:ProgramFiles\Google\Chrome\Application\master_preferences" | Should -Exist
        }
    }
}

Describe -Name "Microsoft 365 Apps" {
    Context "Executables" {
        It "Should have the required executables" {
            "$Env:ProgramFiles\Microsoft Office\root\Office16\WINWORD.EXE" | Should -Exist
        }
    }
}

Describe -Name "General" {
    Context "Shortcuts" {
        It "Should have not shortcuts on the public desktop" {
            "$Env:Public\Desktop\*.lnk" | Should -Not -Exist
        }
    }
}
