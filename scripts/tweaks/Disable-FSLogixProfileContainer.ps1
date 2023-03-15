#description: Disables the Microsoft FSLogix Profile Container. Reboot required.
#execution mode: Combined
#tags: FSLogix, Image

# https://learn.microsoft.com/en-us/fslogix/reference-configuration-settings?tabs=profiles#enabled

reg delete "HKLM\SOFTWARE\FSLogix\Profiles" /v "Enabled" /t "REG_DWORD" /d 0 /f | Out-Null
