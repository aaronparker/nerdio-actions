<#
    .SYNOPSIS
    Installs PowerShell modules required for building AVD images (Evergreen, VcRedist, PSWindowsUpdate, etc.)

    .DESCRIPTION
    This script installs the necessary PowerShell modules for building AVD (Azure Virtual Desktop) images.
    It ensures that the PSGallery is trusted, installs the required package providers,
    and then installs the Evergreen, VcRedist, and PSWindowsUpdate modules if they are not already installed or if a newer version is available.
#>

#description: Installs PowerShell modules required for building AVD images (Evergreen, VcRedist, PSWindowsUpdate, etc.)
#execution mode: Combined
#tags: Evergreen, VcRedist, Image

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

# Trust the PSGallery for modules
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Install-PackageProvider -Name "NuGet" -Force
Write-LogFile -Message "Install PowerShellGet"
Install-PackageProvider -Name "PowerShellGet" -MinimumVersion "2.2.5" -Force
Install-Module -Name "PackageManagement" -Force -Scope "AllUsers" -AllowClobber -SkipPublisherCheck
Write-LogFile -Message "Set PSGallery as trusted"
Write-LogFile -Message "Install PackageManagement"
Set-PSRepository -Name "PSGallery" -InstallationPolicy "Trusted"

# Install the Evergreen module; https://github.com/aaronparker/Evergreen
# Install the VcRedist module; https://docs.stealthpuppy.com/vcredist/
foreach ($Module in "Evergreen", "VcRedist", "PSWindowsUpdate") {
    $params = @{
        Name               = $Module
        SkipPublisherCheck = $true
        Force              = $true
        ErrorAction        = "Stop"
    }
    Write-LogFile -Message "Installing module: $Module"
    Install-Module @params
}
