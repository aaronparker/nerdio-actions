<#
    .SYNOPSIS
        Use Pester to validate application files and services etc.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
[CmdletBinding()]
param()

BeforeDiscovery {
    $Shortcuts = @("$Env:ProgramData\Microsoft\Windows\Start Menu\FSLogix\FSLogix Apps Online Help.lnk",
        "$env:Public\Desktop\Microsoft Edge*.lnk",
        "$Env:ProgramData\Microsoft\Windows\Start Menu\FSLogix\FSLogix Apps Online Help.lnk",
        "$Env:Public\Desktop\Google Chrome.lnk",
        "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\VideoLAN\VLC\VideoLAN website.lnk",
        "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\VideoLAN\VLC\Release Notes.lnk",
        "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\VideoLAN\VLC\Documentation.lnk",
        "$Env:Public\Desktop\VLC media player.lnk",
        "$Env:Public\Desktop\PDF Architect 9.lnk",
        "$Env:Public\Desktop\PDFCreator.lnk",
        "$Env:Public\Desktop\Zoom VDI.lnk"
    )

    $Services = @(
        "AdobeARMservice",
        "FoxitReaderUpdateService",
        "gupdate",
        "gupdatem"
    )
}

Describe -Name "Shortcuts" -ForEach $Shortcuts {
    BeforeAll {
        # Renaming the automatic $_ variable
        $Shortcut = $_
    }

    Context "Validate the shortcut does not exist." {
        It "Should not exist: <Shortcut>" {
            $Shortcut | Should -Not -Exist
        }
    }
}

Describe -Name "Services" -ForEach $Services {
    BeforeAll {
        # Renaming the automatic $_ variable
        $Service = $_
    }

    Context "Validate the service has been disabled." {
        It "Should be disabled: <Service>" {
            (Get-Service -Name $Service).StartType | Should -Be "Disabled"
        }
    }
}

Describe -Name "Microsoft Edge" {
    Context "Application preferences" {
        It "Should have written the correct content to master_preferences" {
            (Get-Content -Path "${Env:ProgramFiles(x86)}\Microsoft\Edge\Application\master_preferences" | ConvertFrom-Json).homepage | Should -BeExactly "https://www.office.com"
        }
    }
}

Describe -Name "Google Chrome" {
    Context "Application preferences" {
        It "Should have written the correct content to master_preferences" {
            (Get-Content -Path "$Env:ProgramFiles\Google\Chrome\Application\master_preferences" | ConvertFrom-Json).homepage | Should -BeExactly "https://www.office.com"
        }
    }
}
