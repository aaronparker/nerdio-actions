#description: Installs the latest Microsoft Edge
#execution mode: Combined
#tags: Evergreen, Edge
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\Edge"

#region Script logic
# Create target folder
try {
    New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

    $App = Get-EvergreenApp -Name "MicrosoftEdge" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Release -eq "Enterprise" } `
    | Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1

    # Download
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

    # Install
    $params = @{
        FilePath     = "$env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package $($OutFile.FullName) /quiet /norestart DONOTCREATEDESKTOPSHORTCUT=true /log `"$env:ProgramData\NerdioManager\Logs\MicrosoftEdge.log`""
        NoNewWindow  = $True
        Wait         = $True
        PassThru     = $True
    }
    Start-Process @params

    # Post install configuration
    $prefs = @{
        "homepage"               = "https://www.office.com"
        "homepage_is_newtabpage" = $False
        "browser"                = @{
            "show_home_button" = $True
        }
        "distribution"           = @{
            "skip_first_run_ui"              = $True
            "show_welcome_page"              = $False
            "import_search_engine"           = $False
            "import_history"                 = $False
            "do_not_create_any_shortcuts"    = $False
            "do_not_create_taskbar_shortcut" = $False
            "do_not_create_desktop_shortcut" = $True
            "do_not_launch_chrome"           = $True
            "make_chrome_default"            = $True
            "make_chrome_default_for_user"   = $True
            "system_level"                   = $True
        }
    }
    $prefs | ConvertTo-Json | Set-Content -Path "${Env:ProgramFiles(x86)}\Microsoft\Edge\Application\master_preferences" -Force -Encoding "utf8"
    Remove-Item -Path "$env:Public\Desktop\Microsoft Edge*.lnk" -Force -ErrorAction "SilentlyContinue"

    # $services = "edgeupdate", "edgeupdatem", "MicrosoftEdgeElevationService"
    # foreach ($service in $services) { Get-Service -Name $service | Set-Service -StartupType "Disabled" }
    # foreach ($task in (Get-ScheduledTask -TaskName *Edge*)) { Unregister-ScheduledTask -TaskName $Task -Confirm:$False -ErrorAction SilentlyContinue }
}
catch {
    throw $_.Exception.Message
}
#endregion
