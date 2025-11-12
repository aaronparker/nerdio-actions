<#
    .SYNOPSIS
    Installs the 1Password Windows client.

    .DESCRIPTION
    This script installs the 1Password Windows client using the Evergreen module.
    It downloads the MSI installer from the specified URI and installs it silently.
    The installation log is saved in the specified log file.

    .PARAMETER Path
    The download path for the 1Password client. The default path is "$Env:SystemDrive\Apps\AgileBits\1Password".
#>

#description: Installs the 1Password Windows client
#execution mode: Combined
#tags: Evergreen, AgileBits, 1Password
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\AgileBits\1Password"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

# Download
Write-LogFile -Message "Query Evergreen for 1Password client"
$App = Get-EvergreenApp -Name "1Password" | Where-Object { $_.Type -eq "msi" } | Select-Object -First 1
Write-LogFile -Message "Downloading 1Password version $($App.Version) to $Path"
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

# Install package
$LogPath = (Get-LogFile).Path
$LogFile = "$LogPath\1Password.log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" /quiet /log $LogFile"
}
Start-ProcessWithLog @params
