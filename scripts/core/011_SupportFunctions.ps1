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
# Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.208" -Force -ErrorAction "Stop"
Install-PackageProvider -Name "PowerShellGet" -MinimumVersion "2.2.5" -Force -ErrorAction "SilentlyContinue"
Set-PSRepository -Name "PSGallery" -InstallationPolicy "Trusted"

# Install the Evergreen module; https://github.com/aaronparker/Evergreen
# Install the VcRedist module; https://docs.stealthpuppy.com/vcredist/
foreach ($Module in "Evergreen", "VcRedist", "PSWindowsUpdate") {
    $InstalledModule = Get-Module -Name $Module -ListAvailable -ErrorAction "SilentlyContinue" | `
        Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } -ErrorAction "SilentlyContinue" | `
        Select-Object -First 1
    $PublishedModule = Find-Module -Name $Module -ErrorAction "SilentlyContinue"
    if (($null -eq $InstalledModule) -or ([System.Version]$PublishedModule.Version -gt [System.Version]$InstalledModule.Version)) {
        $params = @{
            Name               = $Module
            SkipPublisherCheck = $true
            Force              = $true
            ErrorAction        = "Stop"
        }
        Write-Host "Installing module: $Module"
        Install-Module @params
    }
}
#endregion
