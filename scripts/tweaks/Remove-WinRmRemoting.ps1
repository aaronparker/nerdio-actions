#description: Disables WinRM firewall rules and PS Remoting. Only use if you need to disable these features
#execution mode: Combined
#tags: Language, Image

#region Disable WinRM firewall rules and disable PS Remoting
# https://github.com/Azure/RDS-Templates/issues/435
# https://qiita.com/fujinon1109/items/440c614338fe2535b09e
Write-Information -MessageData "Disable-NetFirewallRule 'Windows Remote Management'" -InformationAction "Continue"
Get-NetFirewallRule -DisplayGroup "Windows Remote Management" | Disable-NetFirewallRule
Disable-PSRemoting -Force
#endregion
