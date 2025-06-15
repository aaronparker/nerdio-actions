<#
    .SYNOPSIS
    Installs the latest version of Mozilla Firefox 64-bit with automatic update disabled.

    .DESCRIPTION
    This script installs the latest version of Mozilla Firefox 64-bit with automatic update disabled.
    It uses the Evergreen module to retrieve the appropriate version of Firefox based on the specified language and channel.

    .PARAMETER Path
    The download path for Mozilla Firefox.

    .NOTES
    - Requires the Evergreen module.
    - Uses secure variables in Nerdio Manager to pass a JSON file with the variables list.
    - Logs installation details to the Nerdio Logs directory.
#>

#description: Installs the latest version of Mozilla Firefox 64-bit with automatic update disabled
#execution mode: Combined
#tags: Evergreen, Mozilla, Firefox
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Mozilla\Firefox"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    [System.String] $Language = "en-US"
    [System.String] $Channel = "Current"
}
else {
    $Variables = Get-NerdioVariablesList
    [System.String] $Language = $Variables.$AzureRegionName.FirefoxLanguage
    [System.String] $Channel = $Variables.$AzureRegionName.FirefoxChannel
}
#endregion

Import-Module -Name "Evergreen" -Force
Write-LogFile -Message "Query Evergreen for Mozilla Firefox $Channel $Language x64"
$App = Get-EvergreenApp -Name "MozillaFirefox" | `
    Where-Object { $_.Channel -eq $Channel -and $_.Architecture -eq "x64" -and $_.Language -eq $Language -and $_.Type -eq "msi" } | `
    Select-Object -First 1
Write-LogFile -Message "Downloading Mozilla Firefox version $($App.Version) to $Path"
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$LogPath = (Get-LogFile).Path
$LogFile = "$LogPath\MozillaFirefox$($App.Version).log" -replace " ", ""
$Options = "DESKTOP_SHORTCUT=false
        TASKBAR_SHORTCUT=false
        INSTALL_MAINTENANCE_SERVICE=false
        REMOVE_DISTRIBUTION_DIR=true
        PREVENT_REBOOT_REQUIRED=true
        REGISTER_DEFAULT_AGENT=true"
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" $($Options -replace "\s+", " ") /quiet /log $LogFile"
}
Start-ProcessWithLog @params

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:Public\Desktop\Mozilla Firefox.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
