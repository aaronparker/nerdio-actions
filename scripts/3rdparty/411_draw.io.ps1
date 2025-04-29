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
[System.String] $Path = "$Env:SystemDrive\Apps\draw.io"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "diagrams.net" | Where-Object { $_.Type -eq "msi" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$LogFile = "$Env:SystemRoot\Logs\ImageBuild\diagrams.net$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" ALLUSERS=1 /quiet /log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:Public\Desktop\draw.io.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
