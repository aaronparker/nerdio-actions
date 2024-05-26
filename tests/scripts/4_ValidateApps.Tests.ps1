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
    # Get the list of software to test
    $Applications = Get-Content -Path $([System.IO.Path]::Combine($Path, "tests", "scripts", "Apps.json")) | ConvertFrom-Json
}

BeforeAll {
    # Import module
    Import-Module "Evergreen" -Force
}

# Per script tests
Describe "Validate <App.Name>" -ForEach $Applications {
    BeforeDiscovery {
        $FilesExist = $_.FilesExist
        $FilesNotExist = $_.FilesNotExist
        $ServicesDisabled = $_.ServicesDisabled
        $ServicesEnabled = $_.ServicesEnabled
        $TasksNotExist = $_.TasksNotExist
        $RegDwordValue = $_.RegDwordValue
        $RegStringValue = $_.RegStringValue
        $RegValueNotExits = $_.RegValueNotExits
    }

    BeforeAll {
        #region Functions
        function Get-InstalledSoftware {
            $UninstallKeys = @(
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
            )
            $Apps = @()
            foreach ($Key in $UninstallKeys) {
                try {
                    $propertyNames = "DisplayName", "DisplayVersion", "Publisher", "UninstallString", "PSPath", "WindowsInstaller", "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize", "SystemComponent"
                    $Apps += Get-ItemProperty -Path $Key -Name $propertyNames -ErrorAction "SilentlyContinue" | `
                        . { process { if ($null -ne $_.DisplayName) { $_ } } } | `
                        Where-Object { $_.SystemComponent -ne 1 } | `
                        Select-Object -Property @{n = "Name"; e = { $_.DisplayName } }, @{n = "Version"; e = { $_.DisplayVersion } }, "Publisher", "UninstallString", @{n = "RegistryPath"; e = { $_.PSPath -replace "Microsoft.PowerShell.Core\\Registry::", "" } }, "PSChildName", "WindowsInstaller", "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize" | `
                        Sort-Object -Property "DisplayName", "Publisher"
                }
                catch {
                    throw $_.Exception.Message
                }
            }
            return $Apps
        }
        #endregion

        # Get the Software list; Output the installed software to the pipeline for Packer output
        $InstalledSoftware = Get-InstalledSoftware | Sort-Object -Property "Publisher", "Version"

        # Get details for the current application
        $App = $_

        if ([System.String]::IsNullOrEmpty($App.Filter)) {
            $Latest = [PSCustomObject]@{
                Version = "1.1.0"
            }
        }
        else {
            $Latest = Invoke-Expression -Command $App.Filter
        }

        $Installed = $InstalledSoftware | `
            Where-Object { $_.Name -match $App.Installed } | `
            Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | `
            Select-Object -First 1
    }

    Context "Validate installed application: <App.Name>" {
        It "<App.Name> should be installed" {
            $Installed | Should -Not -BeNullOrEmpty
        }
    }

    Context "Application configuration tests: <App.Name>" {
        It "<App.Name> should be the current version or better" {
            [System.Version]$Installed.Version | Should -BeGreaterOrEqual ([System.Version]$Latest.Version)
        }

        It "<App.Name> should have file installed: <_>" -ForEach $FilesExist {
            $_ | Should -Exist
        }

        It "<App.Name> should have file or shortcut deleted: <_>" -ForEach $FilesNotExist {
            $_ | Should -Not -Exist
        }

        # We need to account for more than one service
        It "Should have the service disabled: <_>" -ForEach $ServicesDisabled {
            (Get-Service -Name $_).StartType | Should -BeIn @("Disabled", "Disabled")
        }

        It "Should have the service enabled: <_>" -ForEach $ServicesEnabled {
            (Get-Service -Name $_).StartType | Should -Be "Automatic"
        }

        It "Should have the scheduled task removed: <_>" -ForEach $TasksNotExist {
            (Get-ScheduledTask -TaskName $_) | Should -BeNullOrEmpty
        }

        It "Should have the registry DWORD value set for: <_.Value>" -ForEach $RegDwordValue {
            $RegKey = Get-Item -Path $_.Key
            $RegKey.GetValue($_.Value) | Should -BeExactly $_.Data
        }

        It "Should have the registry STRING value set for: <_.Value>" -ForEach $RegStringValue {
            $RegKey = Get-Item -Path $_.Key
            $RegKey.GetValue($_.Value) | Should -Be $_.Data
        }

        It "Should have the registry value deleted: <_.Value>" -ForEach $RegValueNotExits {
            $RegKey = Get-Item -Path $_.Key
            $RegKey.GetValue($_.Value) | Should -BeNullOrEmpty
        }
    }
}
