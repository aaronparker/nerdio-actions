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
try {
    # Download
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "MicrosoftEdge" | `
        Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Release -eq "Enterprise" } | `
        Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}

try {
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
        $result = Start-Process @params
        Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
    }
}
catch {
    throw $_.Exception.Message
}

try {
    # Post install configuration
    $prefs = @{
        "homepage"               = "https://www.office.com"
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
}
catch {
    throw $_.Exception.Message
}
#endregion

#region Edge WebView2
try {
    # Download
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "MicrosoftEdgeWebView2Runtime" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" } | `
        Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "Ignore"
}
catch {
    throw $_.Exception.Message
}

try {
    # Install
    Write-Information -MessageData ":: Install Microsoft Edge WebView2" -InformationAction "Continue"
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = "/silent /install"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
}
catch {
    throw $_.Exception.Message
}
#endregion
