#description: Installs the latest Microsoft PowerToys. Requires the Microsoft .NET Runtime
#execution mode: Combined
#tags: Evergreen, Microsoft, PowerToys
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\PowerToys"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "MicrosoftPowerToys" | Where-Object { $_.Architecture -eq "x64" -and $_.InstallerType -eq "Default" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    Write-Information -MessageData ":: Install Microsoft PowerToys" -InformationAction "Continue"
    $LogFile = "$Env:ProgramData\Nerdio\Logs\MicrosoftPowerToys$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = "-silent -log $LogFile"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
}
catch {
    throw $_
}

# Disable features that aren't suitable for VDI
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityAwake" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityHostsFileEditor" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityFileExplorerPDFThumbnails" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityFileExplorerSTLThumbnails" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityFileExplorerSVGThumbnails" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityFileExplorerGcodeThumbnails" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityFileExplorerPDFPreview" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityFileLocksmith" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityVideoConferenceMute" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "AllowExperimentation" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityEnvironmentVariables" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "ConfigureEnabledUtilityMouseWithoutBorders" /d 0 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "PerUserInstallationDisabled" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "SuspendNewUpdateAvailableToast" /d 1 /t "REG_DWORD" /f | Out-Null
reg add "HKLM\Software\Policies\PowerToys" /v "AutomaticUpdateDownloadDisabled" /d 1 /t "REG_DWORD" /f | Out-Null

Start-Sleep -Seconds 5
Get-Process -ErrorAction "SilentlyContinue" | `
    Where-Object { $_.Path -like "$Env:ProgramFiles\PowerToys\*" } | `
    Stop-Process -Force -ErrorAction "SilentlyContinue"
#endregion
