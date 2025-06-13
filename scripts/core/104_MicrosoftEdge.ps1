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
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import the shared functions
$LogPath = "$Env:ProgramData\ImageBuild"
Import-Module -Name "$LogPath\Functions.psm1" -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $LogPath\Functions.psm1"

#region Script logic
# Download
Import-Module -Name "Evergreen" -Force
Write-LogFile -Message "Downloading Microsoft Edge Stable Enterprise x64 version"
$App = Get-EvergreenApp -Name "MicrosoftEdge" | `
    Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Release -eq "Enterprise" } | `
    Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
Write-LogFile -Message "Downloaded Microsoft Edge to: $($OutFile.FullName)"

$File = Get-ChildItem -Path $EdgeExe
if (!(Test-Path -Path $EdgeExe) -or ([System.Version]$File.VersionInfo.ProductVersion -lt [System.Version]$App.Version)) {
    Write-LogFile -Message "Installing Microsoft Edge version: $($App.Version) from: $($OutFile.FullName)"

    # Install
    $LogFile = "$LogPath\ImageBuild\MicrosoftEdge$($App.Version).log" -replace " ", ""
    Write-LogFile -Message "Installing Microsoft Edge from: $($OutFile.FullName)"
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($OutFile.FullName)`" /quiet /norestart DONOTCREATEDESKTOPSHORTCUT=true /log $LogFile"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Stop"
    }
    Start-Process @params
}

# Post install configuration
$prefs = @"
{
    "bookmark_bar": {
        "show_apps_shortcut": true,
        "show_managed_bookmarks": true,
        "show_on_all_tabs": false
    },
    "bookmarks": {
        "editing_enabled": true
    },
    "browser": {
        "clear_data": {
            "browsing_history": true,
            "browsing_history_basic": true,
            "cache": true,
            "cache_basic": true,
            "cookies": true,
            "download_history": true,
            "form_data": false,
            "passwords": false
        },
        "clear_data_on_exit": {
            "browsing_history": false,
            "cache": false,
            "cookies": false,
            "download_history": false,
            "form_data": false,
            "hosted_apps_data": false,
            "passwords": false,
            "site_settings": false
        },
        "dark_theme": true,
        "first_run_tabs": [
            "https://m365.cloud.microsoft/?auth=2"
        ],
        "show_toolbar_bookmarks_button": true,
        "show_toolbar_collections_button": true,
        "show_toolbar_downloads_button": false,
        "show_home_button": true,
        "show_prompt_before_closing_tabs": true,
        "show_toolbar_history_button": true
    },
    "default_search_provider": {
        "enabled": true,
        "search_url": "www.bing.com"
    },
    "fullscreen": {
        "allowed": false
    },
    "homepage": "https://m365.cloud.microsoft/?auth=2",
    "homepage_is_newtabpage": false,
    "history": {
        "clear_on_exit": false,
        "deleting_enabled": true
    },
    "feedback_allowed": false,
    "session": {
        "restore_on_startup": 1,
        "startup_urls": []
    }
}
"@
Write-LogFile -Message "Setting initial preferences for Microsoft Edge"
$prefs | Set-Content -Path "${Env:ProgramFiles(x86)}\Microsoft\Edge\Application\initial_preferences" -Force -Encoding "utf8"
$Shortcuts = @("$Env:Public\Desktop\Microsoft Edge*.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "SilentlyContinue"
#endregion

#region Edge WebView2
# Download
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "MicrosoftEdgeWebView2Runtime" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" } | `
    Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "Ignore"
Write-LogFile -Message "Downloaded Microsoft Edge WebView2 Runtime to: $($OutFile.FullName)"

# Install
Write-LogFile -Message "Installing Microsoft Edge WebView2 Runtime version: $($App.Version) from: $($OutFile.FullName)"
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/silent /install"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params
#endregion
