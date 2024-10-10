<#
    .SYNOPSIS
    This script is used to clean up an image by removing unnecessary registry entries,
    uninstalling specific applications, and removing unnecessary paths and items.

    .DESCRIPTION
    The script performs the following tasks:
    1. Imports the Functions module
    2. Cleans up registry entries related to Windows Store policies
    3. Uninstalls a list of applications included in the image or that are not needed
    4. Removes specific paths from the image
    5. Removes items from the Temp directory
#>

#region Functions
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
#endregion

# Clean up registry entries
if ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption -like "Microsoft Windows 1*") {
    # Remove policies
    Write-LogFile -Message "Run: reg delete HKLM\Software\Policies\Microsoft\WindowsStore /v AutoDownload /f" -LogLevel 1
    reg delete "HKLM\Software\Policies\Microsoft\WindowsStore" /v "AutoDownload" /f
}

# Uninstall a list of applications already included in the image or that we don't need
# Microsoft .NET 6.x installs are in the default Windows Server image from the Azure Marketplace
$Targets = @("Microsoft .NET.*Windows Server Hosting",
    "Microsoft .NET Runtime*",
    "Microsoft ASP.NET Core*",
    "Microsoft OLE DB Driver for SQL Server",
    "Microsoft ODBC Driver 17 for SQL Server",
    "Microsoft Windows Desktop Runtime - 8.0.6")
$Targets | ForEach-Object {
    $Target = $_
    Get-InstalledSoftware | Where-Object { $_.Name -match $Target } | ForEach-Object {
        
        if ($_.UninstallString -match "msiexec") {
            # Match the GUID in the uninstall string
            $GuidMatches = [Regex]::Match($_.UninstallString, "({[A-Z0-9]{8}-([A-Z0-9]{4}-){3}[A-Z0-9]{12}})")
            $params = @{
                FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
                ArgumentList = "/uninstall $($GuidMatches.Value) /quiet /norestart"
                NoNewWindow  = $true
                Wait         = $true
                ErrorAction  = "Continue"
            }
        }
        else {
            # Split the uninstall string to grab the executable path
            $UninstallStrings = $_.UninstallString -split "/"
            $params = @{
                FilePath     = $UninstallStrings[0]
                ArgumentList = "/uninstall /quiet /norestart"
                NoNewWindow  = $true
                Wait         = $true
                ErrorAction  = "Continue"
            }
        }

        # Uninstall the application
        Start-Process @params | Out-Null
    }
}

# Remove paths that we should not need to leave around in the image
if (Test-Path -Path "$Env:SystemDrive\Apps") {
    Remove-Item -Path "$Env:SystemDrive\Apps" -Recurse -Force -ErrorAction "SilentlyContinue"
}
if (Test-Path -Path "$Env:SystemDrive\DeployAgent") {
    Remove-Item -Path "$Env:SystemDrive\DeployAgent" -Recurse -Force -ErrorAction "SilentlyContinue"
}

# Remove items from the Temp directory (note that scripts run as SYSTEM)
Remove-Item -Path $Env:Temp -Recurse -Force -Confirm:$false -ErrorAction "SilentlyContinue"
New-Item -Path $Env:Temp -ItemType "Directory" -ErrorAction "SilentlyContinue" | Out-Null
