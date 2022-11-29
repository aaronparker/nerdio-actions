#description: Reenables Windows settings post image creation
#execution mode: Combined
#tags: Image
[System.String] $Path = "$env:SystemDrive\Apps"

try {
    # Re-enable Defender
    Set-MpPreference -DisableRealtimeMonitoring $false

    # Remove policies
    reg delete HKLM\Software\Policies\Microsoft\Windows\CloudContent /v DisableWindowsConsumerFeatures /f
    reg delete HKLM\Software\Policies\Microsoft\WindowsStore /v AutoDownload /f

    # Remove C:\Apps folder
    if (Test-Path -Path $Path) { Remove-Item -Path $Path -Recurse -Force -ErrorAction "SilentlyContinue" }
}
catch {
    throw $_.Exception.Message
}
