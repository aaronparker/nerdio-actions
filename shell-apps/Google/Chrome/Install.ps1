$Context.Log("Installing Google Chrome")
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
$LogFile = "$Env:SystemRoot\Logs\ImageBuild\GoogleChrome.log"
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/install $($Context.GetAttachedBinary()) /quiet /norestart ALLUSERS=1 /log $LogFile"
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
Start-Process @params

# Post install configuration
$prefs = @{
    "homepage"               = "https://m365.cloud.microsoft/?auth=2"
    "homepage_is_newtabpage" = $false
    "browser"                = @{
        "show_home_button" = $true
    }
    "session"                = @{
        "restore_on_startup" = 4
    }
    "bookmark_bar"           = @{
        "show_on_all_tabs" = $false
    }
    "sync_promo"             = @{
        "show_on_first_run_allowed" = $false
    }
    "distribution"           = @{
        "ping_delay"                                = 60
        "suppress_first_run_bubble"                 = $true
        "create_all_shortcuts"                      = $false
        "do_not_create_desktop_shortcut"            = $true
        "do_not_create_quick_launch_shortcut"       = $true
        "do_not_launch_chrome"                      = $true
        "do_not_register_for_update_launch"         = $true
        "make_chrome_default"                       = $false
        "make_chrome_default_for_user"              = $false
        "suppress_first_run_default_browser_prompt" = $true
        "system_level"                              = $true
        "verbose_logging"                           = $true
    }
}
$prefs | ConvertTo-Json | Set-Content -Path "$Env:ProgramFiles\Google\Chrome\Application\master_preferences" -Force -Encoding "utf8"
$Shortcuts = @("$Env:Public\Desktop\Google Chrome.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"

# Disable update tasks - assuming we're installing on a gold image or updates will be managed
Get-Service -Name "GoogleUpdaterInternalService*" -ErrorAction "SilentlyContinue" | ForEach-Object { Set-Service -Name $_.Name -StartupType "Disabled" -ErrorAction "SilentlyContinue" }
Get-Service -Name "GoogleUpdaterService*" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
Get-Service -Name "GoogleChromeElevationService" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
Get-ScheduledTask -TaskName "GoogleUpdateTaskMachine*" | Unregister-ScheduledTask -Confirm:$false -ErrorAction "SilentlyContinue"
