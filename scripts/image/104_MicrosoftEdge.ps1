<#
.SYNOPSIS
Installs the latest Microsoft Edge and Microsoft Edge WebView2.

.DESCRIPTION
This script installs the latest version of Microsoft Edge and Microsoft Edge WebView2.
It uses the Evergreen module to download and install the appropriate versions based on the specified criteria.

.PARAMETER Path
The path where Microsoft Edge will be downloaded.

.EXAMPLE
.\104_MicrosoftEdge.ps1 -Path "C:\Apps\Microsoft\Edge"

.NOTES
- Requires the Evergreen module.
- This script requires administrative privileges to install Microsoft Edge.
#>

#description: Installs the latest Microsoft Edge and Microsoft Edge WebView2
#execution mode: Combined
#tags: Evergreen, Microsoft, Edge, WebView2
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Edge"
[System.String] $EdgeExe = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

#region Edge
# Download
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "MicrosoftEdge" | `
    Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Release -eq "Enterprise" } | `
    Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

$File = Get-ChildItem -Path $EdgeExe
if (!(Test-Path -Path $EdgeExe) -or ([System.Version]$File.VersionInfo.ProductVersion -lt [System.Version]$App.Version)) {

    # Install
    Write-Information -MessageData ":: Install Microsoft Edge" -InformationAction "Continue"
    $LogFile = "$Env:ProgramData\Nerdio\Logs\MicrosoftEdge$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($OutFile.FullName)`" /quiet /norestart DONOTCREATEDESKTOPSHORTCUT=true /log $LogFile"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    Start-Process @params
}

# Post install configuration
$prefs = @{
    "homepage"               = "https://www.microsoft365.com"
    "homepage_is_newtabpage" = $false
    "browser"                = @{
        "show_home_button" = $true
    }
    "distribution"           = @{
        "skip_first_run_ui"              = $true
        "show_welcome_page"              = $false
        "import_search_engine"           = $false
        "import_history"                 = $false
        "do_not_create_any_shortcuts"    = $false
        "do_not_create_taskbar_shortcut" = $false
        "do_not_create_desktop_shortcut" = $true
        "do_not_launch_chrome"           = $true
        "make_chrome_default"            = $true
        "make_chrome_default_for_user"   = $true
        "system_level"                   = $true
    }
}
$prefs | ConvertTo-Json | Set-Content -Path "${Env:ProgramFiles(x86)}\Microsoft\Edge\Application\master_preferences" -Force -Encoding "utf8"
$Shortcuts = @("$Env:Public\Desktop\Microsoft Edge*.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "SilentlyContinue"
#endregion

#region Edge WebView2
# Download
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "MicrosoftEdgeWebView2Runtime" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" } | `
    Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "Ignore"

# Install
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/silent /install"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Continue"
}
Start-Process @params
#endregion
