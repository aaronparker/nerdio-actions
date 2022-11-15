#description: Preps a RDS/WVD image for customisation.
#execution mode: Combined
#tags: Prep

try {
    # Microsoft Defender (may not work on current versions)
    Set-MpPreference -DisableRealtimeMonitoring $true

    # Prevent Windows from installing stuff during deployment
    reg add HKLM\Software\Policies\Microsoft\Windows\CloudContent /v "DisableWindowsConsumerFeatures" /d 1 /t "REG_DWORD" /f | Out-Null
    reg add HKLM\Software\Policies\Microsoft\WindowsStore /v "AutoDownload" /d 2 /t "REG_DWORD" /f | Out-Null

    # Create the log folder
    New-Item -Path "$env:ProgramData\NerdioManager\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
}
catch {
    throw $_.Exception.Message
}
