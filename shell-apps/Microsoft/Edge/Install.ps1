$Context.Log("Installing Edge")
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
$LogFile = "$Env:SystemRoot\Logs\ImageBuild\MicrosoftEdge.log"
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/install $($Context.GetAttachedBinary()) /quiet /norestart DONOTCREATEDESKTOPSHORTCUT=true /log $LogFile"
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
Start-Process @params

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
$prefs | Set-Content -Path "${Env:ProgramFiles(x86)}\Microsoft\Edge\Application\initial_preferences" -Force -Encoding "utf8"
$Shortcuts = @("$Env:Public\Desktop\Microsoft Edge*.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "SilentlyContinue"
$Context.Log("Install complete")
