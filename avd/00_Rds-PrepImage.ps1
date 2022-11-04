#description: Preps a RDS/WVD image for customisation.
#execution mode: Combined
#tags: Prep

# Ready image
Set-MpPreference -DisableRealtimeMonitoring $true

Write-Verbose -Message "Disable Windows Store updates"
REG add HKLM\Software\Policies\Microsoft\Windows\CloudContent /v "DisableWindowsConsumerFeatures" /d 1 /t "REG_DWORD" /f
REG add HKLM\Software\Policies\Microsoft\WindowsStore /v "AutoDownload" /d 2 /t "REG_DWORD" /f
