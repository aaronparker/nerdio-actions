<#
.SYNOPSIS
Installs PowerShell modules required for building AVD images (Evergreen, VcRedist, PSWindowsUpdate, etc.)

.DESCRIPTION
This script installs the necessary PowerShell modules for building AVD (Azure Virtual Desktop) images.
It ensures that the PSGallery is trusted, installs the required package providers,
and then installs the Evergreen, VcRedist, and PSWindowsUpdate modules if they are not already installed or if a newer version is available.

.PARAMETER None
This script does not accept any parameters.

.EXAMPLE
.\011_SupportFunctions.ps1
Runs the script to install the required PowerShell modules for building AVD images.
#>

#description: Installs PowerShell modules required for building AVD images (Evergreen, VcRedist, PSWindowsUpdate, etc.)
#execution mode: Combined
#tags: Evergreen, VcRedist, Image

#region Script logic
# Trust the PSGallery for modules
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.208" -Force -ErrorAction "SilentlyContinue"
#Install-Module -Name PowerShellGet -Force -AllowClobber
Install-PackageProvider -Name "PowerShellGet" -MinimumVersion "2.2.5" -Force -ErrorAction "SilentlyContinue"
foreach ($Repository in "PSGallery") {
    if (Get-PSRepository | Where-Object { $_.Name -eq $Repository -and $_.InstallationPolicy -ne "Trusted" }) {
        Set-PSRepository -Name $Repository -InstallationPolicy "Trusted"
    }
}

# Install the Evergreen module; https://github.com/aaronparker/Evergreen
# Install the VcRedist module; https://docs.stealthpuppy.com/vcredist/
foreach ($module in "Evergreen", "VcRedist", "PSWindowsUpdate") {
    $installedModule = Get-Module -Name $module -ListAvailable -ErrorAction "SilentlyContinue" | `
        Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } -ErrorAction "SilentlyContinue" | `
        Select-Object -First 1
    $publishedModule = Find-Module -Name $module -ErrorAction "SilentlyContinue"
    if (($null -eq $installedModule) -or ([System.Version]$publishedModule.Version -gt [System.Version]$installedModule.Version)) {
        $params = @{
            Name               = $module
            SkipPublisherCheck = $true
            Force              = $true
            ErrorAction        = "Stop"
        }
        Install-Module @params
    }
}
#endregion
