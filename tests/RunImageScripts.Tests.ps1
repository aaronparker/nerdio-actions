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

Describe -Name "Support scripts" -ForEach $SupportScripts {
    Context "The script <_.Name> runs successfully" {
        It "Should not throw during execution" {
            Write-Host "Running: $($_.FullName)"
            & $_.FullName
        }
    }
}

Describe -Name "Dependency Scripts" -ForEach $DependencyScripts {
    Context "The script <_.Name> runs successfully" {
        It "Should not throw during execution" {
            Write-Host "Running: $($_.FullName)"
            & $_.FullName
        }
    }
}

Describe -Name "Microsoft apps scripts" -ForEach $MicrosoftAppsScripts {
    Context "The script <_.Name> runs successfully" {
        It "Should not throw during execution" {
            Write-Host "Running: $($_.FullName)"
            & $_.FullName
        }
    }
}

Describe -Name "3rd party apps scripts" -ForEach $3rdPartyScripts {
    Context "The script <_.Name> runs successfully" {
        It "Should not throw during execution" {
            Write-Host "Running: $($_.FullName)"
            & $_.FullName
        }
    }
}

Describe -Name "Clean up scripts" -ForEach $CleanupScripts {
    Context "The script <_.Name> runs successfully" {
        It "Should not throw during execution" {
            Write-Host "Running: $($_.FullName)"
            & $_.FullName
        }
    }
}
