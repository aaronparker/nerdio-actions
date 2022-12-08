#description: Reenables settings, removes application installers, and remove logs older than 30 days post image completion
#execution mode: Combined
#tags: Image
[System.String] $Path = "$env:SystemDrive\Apps"

try {
    if ((Get-MpPreference).DisableRealtimeMonitoring -eq $true) {
        # Re-enable Defender
        Set-MpPreference -DisableRealtimeMonitoring $false
    }

    if ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption -like "Microsoft Windows 1*") {
        # Remove policies
        reg delete "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /f
        reg delete "HKLM\Software\Policies\Microsoft\WindowsStore" /v "AutoDownload" /f
    }

    # Remove C:\Apps folder
    if (Test-Path -Path $Path) { Remove-Item -Path $Path -Recurse -Force -ErrorAction "SilentlyContinue" }
}
catch {
    throw $_.Exception.Message
}

# Remove logs older than 30 days
Get-ChildItem -Path "$env:ProgramData\NerdioManager\Logs" -Include "*.*" -Recurse | `
    Where-Object { ($_.LastWriteTime -lt (Get-Date).AddDays(-30)) -and ($_.psIsContainer -eq $false) } | `
    Remove-Item -Force -ErrorAction "Ignore"
