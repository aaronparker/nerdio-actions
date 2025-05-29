<#
    .SYNOPSIS
        Uninstalls Citrix-related software agents from the system.

    .DESCRIPTION
        This script enumerates all installed software on the system and uninstalls applications published by
        Citrix Systems, Inc., UniDesk Corporation, or vast limits GmbH.
        It supports both MSI-based and non-MSI-based uninstallers, running them silently.

    .FUNCTIONS
        Get-InstalledSoftware
            Retrieves a list of installed software from the registry, including details such as name, version, publisher, uninstall string, and other properties.

    .PARAMETER Publishers
        An array of publisher names whose software should be targeted for uninstallation.

    .NOTES
        - Requires administrative privileges to uninstall software.
        - Designed for use on Windows systems.
        - Removes the HKU PSDrive if present to avoid lingering drives.

    .EXAMPLE
        .\Uninstall-CitrixAgents.ps1
        Runs the script and silently uninstalls all Citrix-related agents from the system.
#>

function Get-InstalledSoftware {
    [CmdletBinding()]
    param ()
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

    Remove-PSDrive -Name "HKU" -ErrorAction "SilentlyContinue" | Out-Null
    return $Apps
}

function Uninstall-Software {
    [CmdletBinding()]
    param (
        [System.Object[]]$Application
    )

    begin {
        $LogPath = "$Env:SystemRoot\Logs\Uninstall-CitrixAgents"
        New-Item -Path $LogPath -ItemType Directory -Force -ErrorAction "SilentlyContinue" | Out-Null
    }
    process {
        if ($Application.WindowsInstaller -eq 1) {
            $ArgumentList = "/uninstall `"$($Application.PSChildName)`" /quiet /norestart /log `"$LogPath\$($Application.PSChildName).log`""
            $params = @{
                FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
                ArgumentList = $ArgumentList
                NoNewWindow  = $true
                PassThru     = $false
                Wait         = $true
                ErrorAction  = "Continue"
                Verbose      = $true
            }
            Write-Host "Uninstall: $($Application.Name) $($Application.Version)"
            Write-Host "Path: $Env:SystemRoot\System32\msiexec.exe"
            Write-Host "Arguments: $ArgumentList"
            Start-Process @params
        }
        else {
            # Split the uninstall string to extract the executable and arguments
            $String = $Application.UninstallString -replace "`"", "" -split ".exe"

            switch ($Application.UninstallString) {
                { $Application -match "rundll32" } {
                    # Driver packages
                    $ArgumentList = "$($String[1].Trim())"
                }
                { $Application -match "bootstrapperhelper.exe" } {
                    # Citrix Workspace app
                    $ArgumentList = "$($String[1].Trim()) /silent /norestart"
                }
                { $Application -match "XenDesktopVdaSetup.exe" } {
                    # Citrix Virtual Desktop Agent
                    $ArgumentList = "/remove /REMOVE_APPDISK_ACK /REMOVE_PVD_ACK /quiet /noreboot"
                }
                default {
                    # Other non-MSI uninstallers
                    $ArgumentList = "$($String[1].Trim()) /quiet /norestart /log `"$LogPath\$(Split-Path $String[0].Trim() -Leaf).log`""
                }
            }

            $params = @{
                FilePath     = "$($String[0].Trim()).exe"
                ArgumentList = $ArgumentList
                NoNewWindow  = $true
                PassThru     = $false
                Wait         = $true
                ErrorAction  = "Continue"
                Verbose      = $true
            }
            Write-Host "Uninstall: $($Application.Name) $($Application.Version)"
            Write-Host "Path: $($String[0].Trim()).exe"
            Write-Host "Arguments: $ArgumentList"
            Start-Process @params
        }
    }
}

# $Publishers = "Citrix Systems, Inc.", "vast limits GmbH", "UniDesk Corporation"
# Get-InstalledSoftware | Where-Object { $_.Publisher -in $Publishers } | Out-GridView

$Publishers = "Citrix Systems, Inc.", "vast limits GmbH"
Get-InstalledSoftware | Where-Object { $_.Publisher -in $Publishers } | ForEach-Object {
    Uninstall-Software -Application $_
}

Write-Host "Uninstallation of Citrix agents completed. Please restart the system to finalize the process."

# Remove any lingering Citrix directories if necessary
# Remove-Item -Confirm:$false -Force -Recurse -Path "C:\Program Files\Citrix"
# Remove-Item -Confirm:$false -Force -Recurse -Path "C:\Program Files (x86)\Citrix"
# Remove-Item -Confirm:$false -Force -Recurse -Path "C:\Program Files (x86)\Common Files\Citrix"
