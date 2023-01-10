#description: Enable RDP Shortpath for public networks - reboot required. This configuration should preferably be implemented via GPO.
#execution mode: Combined
#tags: RDP Shortpath, Image, Preview
<#
This configuration should be implemented via GPO
https://learn.microsoft.com/en-us/azure/virtual-desktop/configure-rdp-shortpath
#>

# Add registry keys
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations" /v "ICEControl" /t "REG_DWORD" /d 2 /f | Out-Null
