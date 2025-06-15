<#
    .SYNOPSIS
    Installs the latest 1Password CLI.

    .DESCRIPTION
    This script installs the latest version of the 1Password CLI (Command Line Interface) tool.
    It downloads the specified version of the CLI from the official 1Password website and extracts it to the specified installation path.
    It also adds the installation path to the system's Path environment variable if it doesn't already exist.

    .PARAMETER Path
    The download path for the 1Password CLI. The default value is "$Env:ProgramFiles\1Password CLI".

    .NOTES
    - This script requires the Evergreen module to be installed.
    - The script will create the installation path directory if it doesn't already exist.
    - The script will create a "Logs" directory under "$Env:ProgramData\Nerdio" if it doesn't already exist.
    - The script will download the specified version of the 1Password CLI from the official 1Password website.
    - The downloaded ZIP file will be extracted to the installation path.
    - The downloaded ZIP file will be deleted after extraction.
    - The script will add the installation path to the system's Path environment variable if it doesn't already exist.
#>

#description: Installs the latest 1Password CLI
#execution mode: Combined
#tags: Evergreen, 1Password
#Requires -Modules Evergreen
[System.String] $Path = "$Env:ProgramFiles\1Password CLI"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

# Download - update when Evergreen supports 1Password CLI
Write-LogFile -Message "Query Evergreen for 1Password CLI"
$App = Get-EvergreenApp -Name "1PasswordCLI" | Where-Object { $_.Architecture -eq "x64" } | Select-Object -First 1
Write-LogFile -Message "Downloading 1Password CLI version $($App.Version) to $Path"
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

# Install package
Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force
Remove-Item -Path $OutFile.FullName -Force -ErrorAction "SilentlyContinue"

# Add $Path to the system Path environment variable if it doesn't already exist
if ([System.Environment]::GetEnvironmentVariable($Env:Path) -match "1Password") {}
else {
    [System.Environment]::SetEnvironmentVariable("Path",
        [System.Environment]::GetEnvironmentVariable("Path",
            [System.EnvironmentVariableTarget]::Machine) + ";$Path",
        [System.EnvironmentVariableTarget]::Machine)
}
