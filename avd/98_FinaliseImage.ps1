#description: Reenables Windows settings post image creation
#execution mode: Combined
#tags: Image
[System.String] $Path = "$env:SystemDrive\Apps"

# Re-enable Defender
try {
    Set-MpPreference -DisableRealtimeMonitoring $false

    reg delete HKLM\Software\Policies\Microsoft\Windows\CloudContent /v DisableWindowsConsumerFeatures /f
    reg delete HKLM\Software\Policies\Microsoft\WindowsStore /v AutoDownload /f

    # Remove C:\Apps folder
    if (Test-Path -Path $Path) { Remove-Item -Path $Path -Recurse -Force -ErrorAction "SilentlyContinue" }
}
catch {
    throw $_.Exception.Message
}
