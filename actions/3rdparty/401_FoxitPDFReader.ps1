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
    - The script creates a log file in the "$Env:SystemRoot\Logs\ImageBuild" folder with the name "FoxitPDFReader<version>.log".
    - The script disables the "FoxitReaderUpdateService" service to prevent automatic updates.
#>

#description: Installs the latest Foxit PDF Reader with automatic updates disabled
#execution mode: Combined
#tags: Evergreen, Foxit, PDF
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Foxit\PDFReader"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    [System.String] $Language = "English"
    Write-LogFile -Message "Using default value for Foxit PDF Reader: Language = $Language"
}
else {
    $Variables = Get-NerdioVariablesList
    [System.String] $Language = $Variables.$AzureRegionName.FoxitLanguage
    Write-LogFile -Message "Using secure variable for Foxit PDF Reader: Language = $Language"
}
#endregion

#region Script logic
Write-LogFile -Message "Query Evergreen for Foxit PDF Reader $Language"
$App = Get-EvergreenApp -Name "FoxitReader" | Where-Object { $_.Language -eq $Language } | Select-Object -First 1
Write-LogFile -Message "Downloading Foxit PDF Reader version $($App.Version) to $Path"
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$LogPath = (Get-LogFile).Path
$LogFile = "$LogPath\FoxitPDFReader$($App.Version).log" -replace " ", ""
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
}
Start-ProcessWithLog @params

# Disable update tasks - assuming we're installing on a gold image or updates will be managed
Write-LogFile -Message "Disable services: FoxitReaderUpdateService*"
Get-Service -Name "FoxitReaderUpdateService*" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
#endregion
