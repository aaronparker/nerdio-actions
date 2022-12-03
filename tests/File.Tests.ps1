<#
    .SYNOPSIS
        Use Pester to validate application files
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
[CmdletBinding()]
param()

BeforeDiscovery {
}

Describe -Name "Microsoft Edge" {
    Context "Application preferences" {
        It "Should have written master_preferences" {
            "${Env:ProgramFiles(x86)}\Microsoft\Edge\Application\master_preferences" | Should -Exist
        }

        It "Should have written the correct content to master_preferences" {
            (Get-Content -Path "${Env:ProgramFiles(x86)}\Microsoft\Edge\Application\master_preferences" | ConvertFrom-Json).homepage | Should -BeExactly "https://www.office.com"
        }
    }
}

Describe -Name "Google Chrome" {
    Context "Application preferences" {
        It "Should have written master_preferences" {
            "$Env:ProgramFiles\Google\Chrome\Application\master_preferences" | Should -Exist
        }

        It "Should have written the correct content to master_preferences" {
            (Get-Content -Path "$Env:ProgramFiles\Google\Chrome\Application\master_preferences" | ConvertFrom-Json).homepage | Should -BeExactly "https://www.office.com"
        }
    }
}

Describe -Name "Microsoft 365 Apps" {
    Context "Installed executables" {
        It "Should have WINWORD.EXE installed" {
            "$Env:ProgramFiles\Microsoft Office\root\Office16\WINWORD.EXE" | Should -Exist
        }

        It "Should have officeappguardwin32.exe installed" {
            "$Env:ProgramFiles\Microsoft Office\root\Office16\officeappguardwin32.exe" | Should -Exist
        }

        It "Should have protocolhandler.exe installed" {
            "$Env:ProgramFiles\Microsoft Office\root\Office16\protocolhandler.exe" | Should -Exist
        }
    }
}

# Describe -Name "General" {
#     Context "Shortcuts" {
#         It "Should have no shortcuts on the public desktop" {
#             "$Env:Public\Desktop\*.lnk" | Should -Not -Exist
#         }
#     }
# }
