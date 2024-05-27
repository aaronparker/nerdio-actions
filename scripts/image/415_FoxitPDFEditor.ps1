<#
.SYNOPSIS
Installs the latest Foxit PDF Reader with automatic updates disabled.

.DESCRIPTION
This script installs the latest version of Foxit PDF Reader with automatic updates disabled.
It uses the Evergreen module to retrieve the appropriate version of Foxit PDF Reader based on the specified language.
The installation is performed silently and the installation log is saved in the Nerdio Logs folder.

.PARAMETER Path
Specifies the download path for Foxit PDF Reader. The default path is "$Env:SystemDrive\Apps\Foxit\PDFEditor".

.NOTES
- This script requires the Evergreen module to be installed.
- The script assumes that it is being run on a gold image or that updates will be managed separately.
#>

#description: Installs the latest Foxit PDF Reader with automatic updates disabled
#execution mode: Combined
#tags: Evergreen, Foxit, PDF
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Foxit\PDFEditor"

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
$App = Get-EvergreenApp -Name "FoxitPDFEditor" | Where-Object { $_.Language -eq $Language } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$LogFile = "$Env:ProgramData\Nerdio\Logs\FoxitPDFEditor$($App.Version).log" -replace " ", ""
$Options = "AUTO_UPDATE=0
        NOTINSTALLUPDATE=1
        MAKEDEFAULT=0
        LAUNCHCHECKDEFAULT=0
        SETDEFAULTPRINTER=0
        REMOVEGAREADER=0
        VIEW_IN_BROWSER=0
        DESKTOP_SHORTCUT=0
        STARTMENU_SHORTCUT_UNINSTALL=0
        DISABLE_UNINSTALL_SURVEY=1"
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" $($Options -replace "\s+", " ") ALLUSERS=1 /quiet /log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params
Start-Sleep -Seconds 10

# Disable update tasks - assuming we're installing on a gold image or updates will be managed
Get-Service -Name "FoxitPhantomPDFUpdateService*" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
#endregion
