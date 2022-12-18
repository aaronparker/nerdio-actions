#description: Enable RDP Shortpath for public networks (Preview) on session host VMs
#execution mode: Combined
#tags: Nerdio, Preview
<#
Notes:
This script will setup windows OS for RDP Shortpath for public networks as defined here: 
https://docs.microsoft.com/en-us/azure/virtual-desktop/shortpath-public

This feature is in preview, and it is recommended that you test in a validation environment
before using in production.

A reboot is required after running this script for the configuration to take effect.
#>

# Add registry keys

$WinstationsKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations'
New-ItemProperty -Path $WinstationsKey -Name 'ICEControl' -ErrorAction:SilentlyContinue -PropertyType:dword -Value 2 -Force
