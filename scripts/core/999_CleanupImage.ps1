#description: Cleanup the image at the end of the build process
#execution mode: Combined
#tags: Cleanup, Optimise

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
    $PropertyNames = "DisplayName", "DisplayVersion", "Publisher", "UninstallString", "PSPath", "WindowsInstaller",
    "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize", "SystemComponent"
    ("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*") | `
        ForEach-Object {
        Get-ItemProperty -Path $_ -Name $PropertyNames -ErrorAction "SilentlyContinue" | `
            . { process { if ($null -ne $_.DisplayName) { $_ } } } | `
            Where-Object { $_.SystemComponent -ne 1 } | `
            Select-Object -Property @{n = "Name"; e = { $_.DisplayName } }, @{n = "Version"; e = { $_.DisplayVersion } }, "Publisher",
        "UninstallString", @{n = "RegistryPath"; e = { $_.PSPath -replace "Microsoft.PowerShell.Core\\Registry::", "" } },
        "PSChildName", "WindowsInstaller", "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize" | `
            Sort-Object -Property "Name", "Publisher"
    }
}
#endregion

# Uninstall a list of applications already included in the image or that we don't need
# Microsoft .NET 6.x installs are in the default Windows Server image from the Azure Marketplace
$Targets = @("Microsoft .NET.*Windows Server Hosting",
    "Microsoft .NET Runtime*",
    "Microsoft ASP.NET Core*",
    "Microsoft Windows Desktop Runtime - 8.0.6")
$Targets | ForEach-Object {
    $Target = $_
    Get-InstalledSoftware | Where-Object { $_.Name -match $Target } | ForEach-Object {
        Write-Host "Uninstalling: $($_.Publisher) $($_.Name) $($_.Version)"
        
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
Write-LogFile -Message "Removing unnecessary paths from the image"
Remove-Item -Path "$Env:SystemDrive\Apps" -Recurse -Force -ErrorAction "SilentlyContinue"
Remove-Item -Path "$Env:SystemDrive\DeployAgent" -Recurse -Force -ErrorAction "SilentlyContinue"
Remove-Item -Path "$Env:SystemDrive\Users\AgentInstall.txt" -Force -Confirm:$false -ErrorAction "SilentlyContinue"
Remove-Item -Path "$Env:SystemDrive\Users\AgentBootLoaderInstall.txt" -Force -Confirm:$false -ErrorAction "SilentlyContinue"
Remove-Item -Path "$Env:SystemDrive\%userprofile%" -Recurse -Force -Confirm:$false -ErrorAction "SilentlyContinue"
Remove-Item -Path "$Env:Public\Desktop\*.lnk" -Force -Confirm:$false -ErrorAction "SilentlyContinue"

# Remove items from the Temp directory (note that scripts run as SYSTEM)
Write-Host  "Cleaning up the Temp directory"
Remove-Item -Path $Env:Temp -Recurse -Force -Confirm:$false -ErrorAction "SilentlyContinue"
New-Item -Path $Env:Temp -ItemType "Directory" -ErrorAction "SilentlyContinue" | Out-Null
