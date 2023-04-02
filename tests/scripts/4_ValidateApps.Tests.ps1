<#
    .SYNOPSIS
        Use Pester and Evergreen to validate installed apps.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification = "This OK for the tests files.")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs to log host.")]
[CmdletBinding()]
param()

BeforeDiscovery {

    # Get the list of software to test
    if ([System.String]::IsNullOrWhiteSpace($Env:GITHUB_WORKSPACE)) {
        $Path = $PWD.Path
    }
    else {
        $Path = $Env:GITHUB_WORKSPACE
    }
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
        $ShortcutsNotExist = $_.ShortcutsNotExist
        $ServicesDisabled = $_.ServicesDisabled
    }

    BeforeAll {
        #region Functions
        function Get-InstalledSoftware {
            [OutputType([System.Object[]])]
            [CmdletBinding()]
            param ()

            try {
                try {
                    $params = @{
                        PSProvider  = "Registry"
                        Name        = "HKU"
                        Root        = "HKEY_USERS"
                        ErrorAction = "SilentlyContinue"
                    }
                    New-PSDrive @params | Out-Null
                }
                catch {
                    throw $_.Exception.Message
                }

                $UninstallKeys = @(
                    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
                )
                $UninstallKeys += Get-ChildItem -Path "HKU:" | Where-Object { $_.Name -match "S-\d-\d+-(\d+-){1,14}\d+$" } | ForEach-Object {
                    "HKU:\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
                }

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
            catch {
                throw $_.Exception.Message
            }
            finally {
                Remove-PSDrive "HKU" -ErrorAction "SilentlyContinue" | Out-Null
            }
        }
        #endregion

        # Get the Software list; Output the installed software to the pipeline for Packer output
        $InstalledSoftware = Get-InstalledSoftware | Sort-Object -Property "Publisher", "Version"

        # Get details for the current application
        $App = $_
        $Latest = Invoke-Expression -Command $App.Filter
        $Installed = $InstalledSoftware | `
            Where-Object { $_.Name -match $App.Installed } | `
            Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | `
            Select-Object -First 1
    }

    Context "Validate installed application" {
        It "Should be installed" {
            $Installed | Should -Not -BeNullOrEmpty
        }
    }

    Context "Application configuration tests" {
        It "Should be the current version or better" {
            [System.Version]$Installed.Version | Should -BeGreaterOrEqual ([System.Version]$Latest.Version)
        }

        It "Should have application file installed: <_>" -ForEach $FilesExist {
            $_ | Should -Exist
        }

        It "Should have shortcut deleted or removed: <_>" -ForEach $ShortcutsNotExist {
            $_ | Should -Not -Exist
        }

        It "Should have the service disabled: <_>" -ForEach $ServicesDisabled {
            (Get-Service -Name $_).StartType | Should -Be "Disabled"
        }
    }
}

AfterAll {
    #region Functions
    function Get-InstalledSoftware {
        [OutputType([System.Object[]])]
        [CmdletBinding()]
        param ()

        try {
            try {
                $params = @{
                    PSProvider  = "Registry"
                    Name        = "HKU"
                    Root        = "HKEY_USERS"
                    ErrorAction = "SilentlyContinue"
                }
                New-PSDrive @params | Out-Null
            }
            catch {
                throw $_.Exception.Message
            }

            $UninstallKeys = @(
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
            )
            $UninstallKeys += Get-ChildItem -Path "HKU:" | Where-Object { $_.Name -match "S-\d-\d+-(\d+-){1,14}\d+$" } | ForEach-Object {
                "HKU:\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
            }

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
        catch {
            throw $_.Exception.Message
        }
        finally {
            Remove-PSDrive "HKU" -ErrorAction "SilentlyContinue" | Out-Null
        }
    }
    #endregion

    if ([System.String]::IsNullOrWhiteSpace($Env:GITHUB_WORKSPACE)) {
        $Path = $PWD.Path
    }
    else {
        $Path = $Env:GITHUB_WORKSPACE
    }
    $params = @{
        Path              = "$Path\support\InstalledApplications.csv"
        Encoding          = "Utf8"
        NoTypeInformation = $true
        Verbose           = $true
    }
    Get-InstalledSoftware | Export-Csv @params
}
