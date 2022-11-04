#description: Preps a RDS/WVD image for customisation.
#execution mode: Combined
#tags: Prep

# Microsoft Defender (may not work on current versions)
Set-MpPreference -DisableRealtimeMonitoring $true

# Prevent Windows from installing stuff during deployment
REG add HKLM\Software\Policies\Microsoft\Windows\CloudContent /v "DisableWindowsConsumerFeatures" /d 1 /t "REG_DWORD" /f
REG add HKLM\Software\Policies\Microsoft\WindowsStore /v "AutoDownload" /d 2 /t "REG_DWORD" /f

# Create the log folder
New-Item -Path "$env:ProgramData\NerdioManager\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
