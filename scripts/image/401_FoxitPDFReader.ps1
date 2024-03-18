<#
.SYNOPSIS
Installs the latest Foxit PDF Reader with automatic updates disabled.

.DESCRIPTION
This script installs the latest version of Foxit PDF Reader with automatic updates disabled.
It uses the Evergreen module to retrieve the appropriate version of Foxit PDF Reader based on the specified language.
The installation is performed silently and logs are generated for troubleshooting purposes.
Additionally, the script disables the update tasks assuming that the installation is being performed on a gold image or updates will be managed separately.

.PARAMETER Path
The target folder where Foxit PDF Reader will be downloaded. The default value is "$Env:SystemDrive\Apps\Foxit\PDFReader".

.NOTES
- This script requires the Evergreen module to be installed.
- The script uses secure variables in Nerdio Manager to pass a JSON file with the variables list. If the secure variables are not available, the script defaults to the English language.
- The script requires TLS 1.2 to be enabled on the system.
- The script creates a log file in the "$Env:ProgramData\Nerdio\Logs" folder with the name "FoxitPDFReader<version>.log".
- The script disables the "FoxitReaderUpdateService" service to prevent automatic updates.
#>

#description: Installs the latest Foxit PDF Reader with automatic updates disabled
#execution mode: Combined
#tags: Evergreen, Foxit, PDF
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Foxit\PDFReader"

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    [System.String] $Language = "English"
}
else {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $params = @{
        Uri             = $SecureVars.VariablesList
        UseBasicParsing = $true
        ErrorAction     = "Stop"
    }
    $Variables = Invoke-RestMethod @params
    [System.String] $Language = $Variables.$AzureRegionName.FoxitLanguage
}
#endregion

#region Script logic
# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "FoxitReader" | Where-Object { $_.Language -eq $Language } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

Write-Information -MessageData ":: Install Foxit PDF Reader" -InformationAction "Continue"
$LogFile = "$Env:ProgramData\Nerdio\Logs\FoxitPDFReader$($App.Version).log" -replace " ", ""
$Options = "AUTO_UPDATE=0
        NOTINSTALLUPDATE=1
        MAKEDEFAULT=0
        LAUNCHCHECKDEFAULT=0
        VIEW_IN_BROWSER=0
        DESKTOP_SHORTCUT=0
        STARTMENU_SHORTCUT_UNINSTALL=0
        DISABLE_UNINSTALL_SURVEY=1
        CLEAN=1
        INTERNET_DISABLE=1"
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" $($Options -replace "\s+", " ") ALLUSERS=1 /quiet /log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"

# Disable update tasks - assuming we're installing on a gold image or updates will be managed
Get-Service -Name "FoxitReaderUpdateService*" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
#endregion
