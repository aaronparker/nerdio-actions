#description: Enable RDP Shortpath for managed and public networks - reboot required. This configuration should preferably be implemented via GPO.
#execution mode: Combined
#tags: RDP Shortpath, Image
<#
This configuration should be implemented via GPO
https://learn.microsoft.com/en-us/azure/virtual-desktop/configure-rdp-shortpath
#>

# Add registry keys
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations" /v "fUseUdpPortRedirector" /t "REG_DWORD" /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations" /v "UdpPortNumber" /t "REG_DWORD" /d 3390 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations" /v "ICEControl" /t "REG_DWORD" /d 2 /f

# Add windows firewall rule
$params = @{
    DisplayName = "Remote Desktop - RDP Shortpath (UDP-In)"
    Action      = "Allow"
    Description = "Inbound rule for the Remote Desktop service to allow RDP traffic. [UDP 3390]"
    Group       = "@FirewallAPI.dll,-28752"
    Name        = "RemoteDesktop-UserMode-In-Shortpath-UDP"
    PolicyStore = "PersistentStore"
    Profile      = "Domain", "Private"
    Service     = "TermService"
    Protocol    = "UDP"
    LocalPort   = 3390
    Program     = "$Env:SystemRoot\system32\svchost.exe"
    Enabled     = "true"
    ErrorAction = "Continue"
}
New-NetFirewallRule @params
