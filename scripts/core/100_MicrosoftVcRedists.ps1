<#
    .SYNOPSIS
    Installs the supported Microsoft Visual C++ Redistributables (2012, 2013, 2022).

    .DESCRIPTION
    This script installs the Microsoft Visual C++ Redistributables for the specified versions (2012, 2013, 2022).
    It creates a directory to store the redistributable files and then proceeds to install them silently.

    .PARAMETER Path
    Specifies the path where the redistributable files will be stored. The default path is "$Env:SystemDrive\Apps\Microsoft\VcRedist".

    .EXAMPLE
    .\100_MicrosoftVcRedists.ps1 -Path "C:\Redist"

    This example installs the Microsoft Visual C++ Redistributables in the "C:\Redist" directory.

    .NOTES
    - This script requires the "VcRedist" module to be installed.
    - The script must be run with administrative privileges.
    - The script supports the following versions of Microsoft Visual C++ Redistributables: 2012, 2013, 2022.
#>

#description: Installs the supported Microsoft Visual C++ Redistributables (2012, 2013, 2022)
#execution mode: Combined
#tags: VcRedist, Microsoft
#Requires -Modules VcRedist
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\VcRedist"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

# Run tasks/install apps
Write-LogFile -Message "Installing Microsoft Visual C++ Redistributables"
Import-Module -Name "VcRedist" -Force
Get-VcList | Save-VcRedist -Path $Path | Install-VcRedist -Silent | Out-Null
