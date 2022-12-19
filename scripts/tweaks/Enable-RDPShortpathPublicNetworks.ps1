#description: Enable RDP Shortpath for public networks. Reboot required.
#execution mode: Combined
#tags: RDP Shortpath, Image, Preview
<#
https://docs.microsoft.com/en-us/azure/virtual-desktop/shortpath-public
#>

# Add registry keys
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations" /v "ICEControl" /t "REG_DWORD" /d 2 /f | Out-Null
