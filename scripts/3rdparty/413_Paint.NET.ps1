<#
    .SYNOPSIS
    Installs the latest version of Paint.NET 64-bit with automatic update disabled.

    .DESCRIPTION
    This script installs the latest version of Paint.NET 64-bit with automatic update disabled.
    It uses the Evergreen module to download the Paint.NET installer and extracts it to the specified path.
    The script then installs Paint.NET silently using the extracted MSI file.
    Finally, it removes the desktop shortcut for Paint.NET.

    .PARAMETER Path
    The path where Paint.NET will be downloaded. The default value is "$Env:SystemDrive\Apps\Paint.NET".

    .NOTES
    - This script requires the Evergreen module to be installed.
    - The script must be run with administrative privileges.
#>

#description: Installs the latest Paint.NET 64-bit
#execution mode: Combined
#tags: Evergreen, Paint.NET
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Paint.NET"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

Import-Module -Name "Evergreen" -Force
Write-LogFile -Message "Query Evergreen for Paint.NET 64-bit"
$App = Get-EvergreenApp -Name "PaintDotNetOfflineInstaller" | `
    Where-Object { $_.Architecture -eq "x64" -and $_.URI -match "winmsi" } | Select-Object -First 1
Write-LogFile -Message "Downloading Paint.NET version $($App.Version) to $Path"
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$params = @{
    Path            = $OutFile.FullName
    DestinationPath = $Path
    Force           = $true
    ErrorAction     = "Stop"
}
Expand-Archive @params

$LogPath = (Get-LogFile).Path
$LogFile = "$LogPath\Paint.NET$($App.Version).log" -replace " ", ""
$Installer = Get-ChildItem -Path $Path -Include "paint*.msi" -Recurse
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($Installer.FullName)`" DESKTOPSHORTCUT=0 CHECKFORUPDATES=0 CHECKFORBETAS=0 /quiet /log $LogFile"
}
Start-ProcessWithLog @params

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:Public\Desktop\Paint.NET.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
