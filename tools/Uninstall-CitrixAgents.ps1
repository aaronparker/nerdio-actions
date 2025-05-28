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

$Publishers = "Citrix Systems, Inc.", "UniDesk Corporation", "vast limits GmbH", "Citrix Systems, Inc."
Get-InstalledSoftware | Where-Object { $_.Publisher -in $Publishers } | ForEach-Object {
    if ($_.WindowsInstaller -eq 1) {
        $params = @{
            FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
            ArgumentList = "/uninstall `"$($_.PSChildName)`" /quiet"
            NoNewWindow  = $true
            PassThru     = $true
            Wait         = $true
            ErrorAction  = "Continue"
            Verbose      = $true
        }
        #$params
        Start-Process @params
    }
    else {
        $String = $_.UninstallString -replace "`"", "" -split ".exe"
        $params = @{
            FilePath     = "$($String[0].Trim()).exe"
            ArgumentList = "$($String[1].Trim()) /quiet /norestart /silent"
            NoNewWindow  = $true
            PassThru     = $true
            Wait         = $true
            ErrorAction  = "Continue"
            Verbose      = $true
        }
        #$params
        Start-Process @params
    }
}
