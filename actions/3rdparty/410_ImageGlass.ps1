<#
    .SYNOPSIS
    Installs the latest version of ImageGlass 64-bit.

    .DESCRIPTION
    This script installs the latest version of ImageGlass, a lightweight image viewer for Windows.
    It uses the Evergreen module to download and install the ImageGlass MSI package.
    The script creates the necessary directories and logs the installation process. It also removes any existing shortcuts related to ImageGlass.

    .PARAMETER Path
    The download path for ImageGlass. The default value is "$Env:SystemDrive\Apps\ImageGlass".

    .NOTES
    - This script requires the Evergreen module to be installed.
    - This script is designed for 64-bit systems.
    - This script requires administrative privileges to install ImageGlass.
#>

#description: Installs the latest ImageGlass 64-bit
#execution mode: Combined
#tags: Evergreen, ImageGlass
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\ImageGlass"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

Write-LogFile -Message "Query Evergreen for ImageGlass 64-bit"
$App = Get-EvergreenApp -Name "ImageGlass" | Where-Object { $_.Architecture -eq "x64" -and $_.Type -eq "msi" } | Select-Object -First 1
Write-LogFile -Message "Downloading ImageGlass version $($App.Version) to $Path"
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$LogPath = (Get-LogFile).Path
$LogFile = "$LogPath\ImageGlass$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" RUNAPPLICATION=0 ALLUSERS=1 /quiet /log $LogFile"
}
Start-ProcessWithLog @params

Start-Sleep -Seconds 5
Write-LogFile -Message "Removing ImageGlass shortcuts."
$Shortcuts = @("$Env:Public\Desktop\ImageGlass.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\ImageGlass\ImageGlass' LICENSE.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\ImageGlass\Uninstall ImageGlass*.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
