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

# Evergreen: https://eucpilots.com/evergreen-docs/
# VcRedist: https://vcredist.com/
# PSWindowsUpdate: https://www.powershellgallery.com/packages/PSWindowsUpdate
Set-PSRepository -Name "PSGallery" -InstallationPolicy "Trusted"
Write-LogFile -Message "Install-Module: PSWindowsUpdate" -LogLevel 1
Install-Module -Name "PSWindowsUpdate" -Scope CurrentUser -Force
Write-LogFile -Message "Install-Module: VcRedist" -LogLevel 1
Install-Module -Name "VcRedist" -Scope CurrentUser -Force
Write-LogFile -Message "Install-Module: Evergreen" -LogLevel 1
Install-Module -Name "Evergreen" -AllowPrerelease
Update-Evergreen
