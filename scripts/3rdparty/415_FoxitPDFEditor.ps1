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
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    Write-LogFile -Message "Using default values for Foxit PDF Editor installation."
    [System.String] $Language = "English"
}
else {
    $Variables = Get-NerdioVariablesList
    Write-LogFile -Message "Using secure variables for Foxit PDF Editor installation."
    [System.String] $Language = $Variables.$AzureRegionName.FoxitLanguage
}
#endregion

#region Script logic
# Create target folder
Import-Module -Name "Evergreen" -Force
Write-LogFile -Message "Query Evergreen for Foxit PDF Editor"
$App = Get-EvergreenApp -Name "FoxitPDFEditor" | Where-Object { $_.Language -eq $Language } | Select-Object -First 1
Write-LogFile -Message "Downloading Foxit PDF Editor version $($App.Version) to $Path"
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$LogPath = (Get-LogFile).Path
$LogFile = "$LogPath\FoxitPDFEditor$($App.Version).log" -replace " ", ""
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
}
Start-ProcessWithLog @params
Start-Sleep -Seconds 10

# Disable update tasks - assuming we're installing on a gold image or updates will be managed
Write-LogFile -Message "Stop service: FoxitPhantomPDFUpdateService*"
Get-Service -Name "FoxitPhantomPDFUpdateService*" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
#endregion
