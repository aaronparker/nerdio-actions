$params = @{
    FilePath     = $Context.GetAttachedBinary()
    ArgumentList = "-silent"
    Wait         = $true
    PassThru     = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
$Context.Log("Install complete. Return code: $($result.ExitCode)")

# Configure PowerToys settings appropriate for VDI environments
$Context.Log("Configure PowerToys registry settings to optimise for virtual desktops.")
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v AllowExperimentation /d 0 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v ConfigureEnabledUtilityAwake /d 0 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v ConfigureEnabledUtilityEnvironmentVariables /d 0 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v ConfigureEnabledUtilityFileLocksmith /d 0 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v ConfigureEnabledUtilityFileExplorerGcodePreview /d 0 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v ConfigureEnabledUtilityFileExplorerGcodeThumbnails /d 0 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v ConfigureEnabledUtilityHostsFileEditor /d 0 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v ConfigureEnabledUtilityFileExplorerPDFPreview /d 0 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v ConfigureEnabledUtilityFileExplorerPDFThumbnails /d 0 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v ConfigureEnabledUtilityFileExplorerQOIPreview /d 0 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v ConfigureEnabledUtilityFileExplorerQOIThumbnails /d 0 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v ConfigureEnabledUtilityFileExplorerSTLThumbnails /d 0 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v ConfigureEnabledUtilityFileExplorerSVGThumbnails /d 0 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v ConfigureEnabledUtilityVideoConferenceMute /d 0 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v DisableNewUpdateAvailableToast /d 1 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v AutomaticUpdateDownloadDisabled /d 1 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v PerUserInstallationDisabled /d 1 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v DoNotShowWhatsNewAfterUpdates /d 1 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v SuspendNewUpdateAvailableToast /d 1 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v ConfigureEnabledUtilityCmdNotFound /d 0 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v ConfigureEnabledUtilityPeek /d 0 /t REG_DWORD /f"
Start-Process -Wait -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "add HKLM\Software\Policies\PowerToys /v ConfigureEnabledUtilityMouseWithoutBorders /d 0 /t REG_DWORD /f"

Start-Sleep -Seconds 5
Get-Process -ErrorAction "SilentlyContinue" | `
    Where-Object { $_.Path -like "$Env:ProgramFiles\PowerToys\*" } | `
    ForEach-Object {
    $Context.Log("Stopping process: $($_.Name)")
    Stop-Process -Force -ErrorAction "SilentlyContinue"
}
