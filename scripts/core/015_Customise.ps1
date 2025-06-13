<#
    .SYNOPSIS
    Installs Windows Enterprise Defaults to customize the image and the default profile.

    .DESCRIPTION
    This script installs Windows Enterprise Defaults to customize the image and the default profile.
    It retrieves the necessary variables from Nerdio Manager or uses default values if no variables are provided. The script then downloads and extracts the installer,
    and runs the Install-Defaults.ps1 script with the specified language, time zone, and Appx mode.

    .PARAMETER Path
    The path where the Windows Enterprise Defaults will be installed.

    .EXAMPLE
    .\015_Customise.ps1 -Path "C:\Apps\defaults"
#>

#description: Installs Windows Enterprise Defaults to customise the image and the default profile https://stealthpuppy.com/defaults/
#execution mode: Combined
#tags: Evergreen, Customisation, Language, Image
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\defaults"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import the shared functions
$LogPath = "$Env:ProgramData\ImageBuild"
Import-Module -Name "$LogPath\Functions.psm1" -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $LogPath\Functions.psm1"

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    [System.String] $Language = "en-AU"
    [System.String] $TimeZone = "AUS Eastern Standard Time"
    Write-LogFile -Message "Using default language: $Language and time zone: $TimeZone"
}
else {
    $Variables = Get-NerdioVariablesList
    [System.String] $Language = $Variables.$AzureRegionName.Language
    [System.String] $TimeZone = $Variables.$AzureRegionName.TimeZone
    Write-LogFile -Message "Using language: $Language and time zone: $TimeZone"
}
#endregion

#region Script logic
$Installer = Get-EvergreenApp -Name "WindowsEnterpriseDefaults" | Where-Object { $_.Type -eq "zip" } | `
    Select-Object -First 1 | `
    Save-EvergreenApp -CustomPath $Path
Write-LogFile -Message "Installer downloaded to: $($Installer.FullName)"

# Extract the installer
Expand-Archive -Path $Installer.FullName -DestinationPath $Path -Force
$InstallFile = Get-ChildItem -Path $Path -Recurse -Include "Install-Defaults.ps1"

# Install the Windows Enterprise Defaults
Push-Location -Path $InstallFile.Directory
Write-LogFile -Message "Running Windows Enterprise Defaults from: $($InstallFile.Directory)"
& "$($InstallFile.Directory.FullName)\Remove-AppXApps.ps1"
Import-Module -Name "$($InstallFile.Directory.FullName)\Install-Defaults.psm1" -Force
& "$($InstallFile.Directory.FullName)\Install-Defaults.ps1" -Language $Language -TimeZone $TimeZone
Pop-Location
#endregion
