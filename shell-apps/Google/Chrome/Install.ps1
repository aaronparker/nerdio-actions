$Context.Log("Installing Google Chrome")
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package $($Context.GetAttachedBinary()) /quiet /norestart ALLUSERS=1"
    Wait         = $true
    PassThru     = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
$Context.Log("Install complete. Return code: $($result.ExitCode)")

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
$Context.Log("Write file: '$Env:ProgramFiles\Google\Chrome\Application\master_preferences'.")
$prefs | ConvertTo-Json | Set-Content -Path "$Env:ProgramFiles\Google\Chrome\Application\master_preferences" -Force -Encoding "utf8"

# Remove shortcuts
$Shortcuts = @("$Env:Public\Desktop\Google Chrome.lnk")
Get-Item -Path $Shortcuts | `
    ForEach-Object { $Context.Log("Remove file: $($_.FullName)"); Remove-Item -Path $_.FullName -Force -ErrorAction "SilentlyContinue" }

# Disable update tasks - assuming we're installing on a gold image or updates will be managed
Get-Service -Name "GoogleUpdater*", "GoogleChromeElevationService" -ErrorAction "SilentlyContinue" | `
    ForEach-Object { $Context.Log("Disable service: $($_.Name)"); Set-Service -Name $_.Name -StartupType "Disabled" -ErrorAction "SilentlyContinue" }
Get-ScheduledTask -TaskName "GoogleUpdateTaskMachine*" -ErrorAction "SilentlyContinue" | `
    ForEach-Object { $Context.Log("Unregister task: $($_.TaskName)"); Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false -ErrorAction "SilentlyContinue" }
