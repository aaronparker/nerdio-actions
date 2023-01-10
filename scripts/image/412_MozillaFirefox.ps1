#description: Installs the latest version of Mozilla Firefox 64-bit with automatic update disabled
#execution mode: Combined
#tags: Evergreen, Mozilla, Firefox
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Mozilla\Firefox"

#region Use Secure variables in Nerdio Manager to pass a language
if ($null -eq $SecureVars.FirefoxLanguage) {
    [System.String] $Language = "en-US"
}
else {
    [System.String] $Language = $SecureVars.FirefoxLanguage
}
#endregion

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "MozillaFirefox" | `
        Where-Object { $_.Channel -eq "LATEST_FIREFOX_VERSION" -and $_.Architecture -eq "x64" -and $_.Language -eq $Language -and $_.Type -eq "msi" } | `
        Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    $LogFile = "$env:ProgramData\Evergreen\Logs\MozillaFirefox$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = "$env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($OutFile.FullName)`" DESKTOP_SHORTCUT=false TASKBAR_SHORTCUT=false INSTALL_MAINTENANCE_SERVICE=false REMOVE_DISTRIBUTION_DIR=true PREVENT_REBOOT_REQUIRED=true REGISTER_DEFAULT_AGENT=true /quiet /log $LogFile"
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

Start-Sleep -Seconds 5
$Shortcuts = @("$env:Public\Desktop\Mozilla Firefox.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
