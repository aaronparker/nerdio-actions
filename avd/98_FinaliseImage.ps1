#description: Reenables Windows settings post image creation
#execution mode: Combined
#tags: Image
[System.String] $Path = "$env:SystemDrive\Apps"

# Re-enable Defender
Set-MpPreference -DisableRealtimeMonitoring $false

reg delete HKLM\Software\Policies\Microsoft\Windows\CloudContent /v DisableWindowsConsumerFeatures /f
reg delete HKLM\Software\Policies\Microsoft\WindowsStore /v AutoDownload /f

# Remove C:\Apps folder
try {
    if (Test-Path -Path $Path) { Remove-Item -Path $Path -Recurse -Force -ErrorAction "SilentlyContinue" }
}
catch {
    Write-Warning "Failed to remove $Path with: $($_.Exception.Message)."
}
