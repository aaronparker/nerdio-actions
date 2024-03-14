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

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    [System.String] $Language = "en-US"
    [System.String] $Channel = "LATEST_FIREFOX_VERSION"
}
else {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $params = @{
        Uri             = $SecureVars.VariablesList
        UseBasicParsing = $true
        ErrorAction     = "Stop"
    }
    $Variables = Invoke-RestMethod @params
    [System.String] $Language = $Variables.$AzureRegionName.FirefoxLanguage
    [System.String] $Channel = $Variables.$AzureRegionName.FirefoxChannel
}
#endregion

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "MozillaFirefox" | `
    Where-Object { $_.Channel -eq $Channel -and $_.Architecture -eq "x64" -and $_.Language -eq $Language -and $_.Type -eq "msi" } | `
    Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

Write-Information -MessageData ":: Install Mozilla Firefox" -InformationAction "Continue"
$LogFile = "$Env:ProgramData\Nerdio\Logs\MozillaFirefox$($App.Version).log" -replace " ", ""
$Options = "DESKTOP_SHORTCUT=false
        TASKBAR_SHORTCUT=false
        INSTALL_MAINTENANCE_SERVICE=false
        REMOVE_DISTRIBUTION_DIR=true
        PREVENT_REBOOT_REQUIRED=true
        REGISTER_DEFAULT_AGENT=true"
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" $($Options -replace "\s+", " ") /quiet /log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:Public\Desktop\Mozilla Firefox.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
