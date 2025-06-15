<#
    .SYNOPSIS
    Installs the latest Google Chrome 64-bit with automatic updates disabled.

    .DESCRIPTION
    This script installs the latest version of Google Chrome 64-bit with automatic updates disabled.
    It also configures various policies for roaming and cache.

    .PARAMETER Path
    Specifies the download path for Google Chrome. The default path is "$Env:SystemDrive\Apps\Google\Chrome".

    .NOTES
    - This script requires the "Evergreen" module.
    - The script assumes that it is being run on a gold image or that updates will be managed separately.
    - For more information on configuring Chrome browser in a VDI environment, refer to the following link: https://cloud.google.com/blog/products/chrome-enterprise/configuring-chrome-browser-in-your-vdi-environment
#>

#description: Installs the latest Google Chrome 64-bit with automatic updates disabled
#execution mode: Combined
#tags: Evergreen, Google, Chrome
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Google\Chrome"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

# Configure policies for roaming and cache
# https://cloud.google.com/blog/products/chrome-enterprise/configuring-chrome-browser-in-your-vdi-environment

Import-Module -Name "Evergreen" -Force
Write-LogFile -Message "Query Evergreen for Google Chrome x64 stable MSI"
$App = Get-EvergreenApp -Name "GoogleChrome" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "stable" -and $_.Type -eq "msi" } | Select-Object -First 1
Write-LogFile -Message "Downloading Google Chrome version $($App.Version) to $Path"
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$LogPath = (Get-LogFile).Path
$LogFile = "$LogPath\GoogleChrome$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" ALLUSERS=1 /quiet /log $LogFile"
}
Start-ProcessWithLog @params

# Post install configuration
$prefs = @{
    "homepage"               = "https://www.microsoft365.com"
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
Write-LogFile -Message "Writing master_preferences file to: $Env:ProgramFiles\Google\Chrome\Application\master_preferences"
$prefs | ConvertTo-Json | Set-Content -Path "$Env:ProgramFiles\Google\Chrome\Application\master_preferences" -Force -Encoding "utf8"
$Shortcuts = @("$Env:Public\Desktop\Google Chrome.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"

# Disable update tasks - assuming we're installing on a gold image or updates will be managed
Write-LogFile -Message "Disabling Google Chrome update tasks and services"
Get-Service -Name "GoogleUpdaterInternalService*" -ErrorAction "SilentlyContinue" | ForEach-Object { Set-Service -Name $_.Name -StartupType "Disabled" -ErrorAction "SilentlyContinue" }
Get-Service -Name "GoogleUpdaterService*" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
Get-Service -Name "GoogleChromeElevationService" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
Get-ScheduledTask -TaskName "GoogleUpdateTaskMachine*" | Unregister-ScheduledTask -Confirm:$false -ErrorAction "SilentlyContinue"
