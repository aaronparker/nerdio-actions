#description: Preps a RDS / AVD image for customisation.
#execution mode: Combined
#tags: Image

try {
    if ((Get-MpPreference).DisableRealtimeMonitoring -eq $false) {
        # Microsoft Defender (may not work on current versions)
        Set-MpPreference -DisableRealtimeMonitoring $true
    }

    if ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption -like "Microsoft Windows 1*") {
        # Prevent Windows from installing stuff during deployment
        reg add HKLM\Software\Policies\Microsoft\Windows\CloudContent /v "DisableWindowsConsumerFeatures" /d 1 /t "REG_DWORD" /f | Out-Null
        reg add HKLM\Software\Policies\Microsoft\WindowsStore /v "AutoDownload" /d 2 /t "REG_DWORD" /f | Out-Null
    }
}
catch {
    throw $_.Exception.Message
}
