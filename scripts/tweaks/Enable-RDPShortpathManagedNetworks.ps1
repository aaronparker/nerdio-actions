#description: Enable RDP Shortpath on each session host VMs
#execution mode: Combined
#tags: Nerdio
<#
Notes:
This script will setup windows OS for shortpath as defined here: https://docs.microsoft.com/en-us/azure/virtual-desktop/shortpath
A reboot is required after running this script for the configuration to take effect.
Please read the MS Doc to ensure Direct line of sight and NSG rules are considered in your environment!
#>

# Add registry keys
$WinstationsKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations'
New-ItemProperty -Path $WinstationsKey -Name 'fUseUdpPortRedirector' -ErrorAction:SilentlyContinue -PropertyType:dword -Value 1 -Force
New-ItemProperty -Path $WinstationsKey -Name 'UdpPortNumber' -ErrorAction:SilentlyContinue -PropertyType:dword -Value 3390 -Force

# Add windows firewall rule for shortpath RDP
New-NetFirewallRule -DisplayName 'Remote Desktop - Shortpath (UDP-In)' `
    -Action Allow `
    -Description 'Inbound rule for the Remote Desktop service to allow RDP traffic. [UDP 3390]' `
    -Group '@FirewallAPI.dll,-28752' `
    -Name 'RemoteDesktop-UserMode-In-Shortpath-UDP' `
    -PolicyStore PersistentStore `
    -Profile Domain, Private `
    -Service TermService `
    -Protocol udp `
    -LocalPort 3390 `
    -Program '%SystemRoot%\system32\svchost.exe' `
    -Enabled:True
