#description: Set a specified framerate for RDP - sets framerate to 60 FPS by default, unless RdpFrameRate is passed via Secure Variables
#execution mode: Combined
#tags: RDP, Framerate

# https://learn.microsoft.com/en-us/troubleshoot/windows-server/remote/frame-rate-limited-to-30-fps

if ($null -eq $SecureVars.RdpFrameRate) {
    $RdpFrameRate = "15"
}
else {
    $RdpFrameRate = $SecureVars.RdpFrameRate
}

# Add registry keys
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations" /v "DWMFRAMEINTERVAL" /t "REG_DWORD" /d $RdpFrameRate /f | Out-Null
