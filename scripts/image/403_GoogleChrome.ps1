#description: Installs the latest Google Chrome 64-bit with automatic updates disabled
#execution mode: Combined
#tags: Evergreen, Google, Chrome
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Google\Chrome"

# Configure policies for roaming and cache
# https://cloud.google.com/blog/products/chrome-enterprise/configuring-chrome-browser-in-your-vdi-environment

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "GoogleChrome" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "stable" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    $LogFile = "$Env:ProgramData\Evergreen\Logs\GoogleChrome$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($OutFile.FullName)`" ALLUSERS=1 /quiet /log $LogFile"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    $result.ExitCode
}
catch {
    throw $_
}

try {
    # Post install configuration
    $prefs = @{
        "homepage"               = "https://www.office.com"
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
}
catch {
    throw $_.Exception.Message
}

try {
    # Disable update tasks - assuming we're installing on a gold image or updates will be managed
    Get-Service -Name "gupdate*" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
    Get-Service -Name "GoogleChromeElevationService" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
    Get-ScheduledTask -TaskName "GoogleUpdateTaskMachine*" | Unregister-ScheduledTask -Confirm:$false -ErrorAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}
#endregion
