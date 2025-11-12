#description: Ignore the keyboard layout of the endpoint and keep the selected input language in the AVD session host
#execution mode: Combined
#tags: Keyboard, Language, Image

# Add the registry value
# https://dennisspan.com/solving-keyboard-layout-issues-in-an-ica-or-rdp-session/
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v "IgnoreRemoteKeyboardLayout" /d 1 /t "REG_DWORD" /f
