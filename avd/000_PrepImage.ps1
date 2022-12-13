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
        reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /d 1 /t "REG_DWORD" /f | Out-Null
        reg add "HKLM\Software\Policies\Microsoft\WindowsStore" /v "AutoDownload" /d 2 /t "REG_DWORD" /f | Out-Null
    }

    New-Item -Path "$env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\compact.exe"
        ArgumentList = "/C /S `"$env:ProgramData\Evergreen\Logs`""
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $false
    }
    Start-Process @params
}
catch {
    throw $_.Exception.Message
}
