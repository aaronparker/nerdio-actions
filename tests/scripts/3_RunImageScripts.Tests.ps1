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
    $SupportScripts = Get-ChildItem -Path $Path -Include "0*.ps1" -Recurse -Exclude "012_WindowsUpdate.ps1"
    $DependencyScripts = Get-ChildItem -Path $Path -Include "1*.ps1" -Recurse -Exclude "101_Avd-AgentMicrosoftWvdMultimediaRedirection"
    $MicrosoftAppsScripts = Get-ChildItem -Path $Path -Include "2*.ps1" -Recurse
    $3rdPartyScripts = Get-ChildItem -Path $Path -Include "4*.ps1" -Recurse -Exclude "420_1Password.ps1", "421_1PasswordCli.ps1", "412_MozillaFirefox.ps1", "417_CitrixWorkspaceApp.ps1"
    $CleanupScripts = Get-ChildItem -Path $Path -Include "9*.ps1" -Recurse

    # Get scripts to run a 2nd time
    $2ndRunScripts = Get-ChildItem -Path $Path -Include "201_MicrosoftTeams.ps1" -Recurse
}

Describe "Run application image scripts with required modules installed" {
    BeforeAll {
        # Path to a custom Office configuration file
        Write-Host "Set Env:OfficeConfig to: $Path\configs\Microsoft365Apps-Outlook-Shared.xml"
        $Env:OfficeConfig = "$Path\configs\Microsoft365Apps-Outlook-Shared.xml"
    }

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

    # Export installs apps list
    New-Item -Path "$Path\support" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
    $params = @{
        Path              = "$Path\support\InstalledApplications.csv"
        Encoding          = "Utf8"
        NoTypeInformation = $true
        Verbose           = $true
    }
    Get-InstalledSoftware | Export-Csv @params

    # Copy logs for upload to the pipeline
    New-Item -Path "$Path\support\logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
    Copy-Item -Path "$Env:ProgramData\Nerdio\Logs\*" -Destination "$Path\support\logs"
}
