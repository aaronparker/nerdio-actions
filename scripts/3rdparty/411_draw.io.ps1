<#
    .SYNOPSIS
    Installs the latest version of draw.io.

    .DESCRIPTION
    This script installs the latest version of draw.io using the Evergreen module.
    It creates a directory for draw.io, imports the Evergreen module, retrieves the latest version of the diagrams.net MSI package,
    saves it to the draw.io directory, and then installs draw.io silently using msiexec.exe.

    .PARAMETER Path
    The path where draw.io will be downloaded. The default path is "$Env:SystemDrive\Apps\draw.io".

    .NOTES
    - This script requires the Evergreen module to be installed.
    - The script will create a log file in "$Env:SystemRoot\Logs\ImageBuild" to track the installation progress.
    - The script will remove the draw.io shortcut from the desktop after installation.
#>

#description: Installs the latest draw.io
#execution mode: Combined
#tags: Evergreen, draw.io
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\drawio"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

Import-Module -Name "Evergreen" -Force
Write-LogFile -Message "Query Evergreen for JGraphDrawIO MSI"
$App = Get-EvergreenApp -Name "JGraphDrawIO" | Where-Object { $_.Type -eq "msi" } | Select-Object -First 1
Write-LogFile -Message "Downloading draw.io version $($App.Version) to $Path"
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$LogPath = (Get-LogFile).Path
$LogFile = "$LogPath\drawio$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" ALLUSERS=1 /quiet /log $LogFile"
}
Start-ProcessWithLog @params

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:Public\Desktop\draw.io.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
