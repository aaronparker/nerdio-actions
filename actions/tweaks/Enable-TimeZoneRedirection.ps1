#description: Enable time zone redirection in RDP sessions
#execution mode: Combined
#tags: Keyboard, Language, Image

# Enable time zone redirection - this can be configure via policy as well
reg add "HKLM\Software\Policies\Microsoft\Windows NT\Terminal Services" /v fEnableTimeZoneRedirection /d 1 /t REG_DWORD /f
