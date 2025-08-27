#Requires -Modules Citrix.CloudServices.Sdk.Proxy
Add-PSSnapin -DisplayName "Citrix*"

# Authenticate to Citrix Cloud
Get-XDAuthentication

# $FullCloneType = @("VCenter","VmwareFactory","XenServer","XenFactory","SCVMM","MicrosoftPSFactory")

# Export assignments for "Single-session OS static (assigned)"
Get-BrokerMachine |
  Where-Object { $_.AllocationType -eq "Permanent" -and $_.ProvisioningType -eq "MCS" } |
  Select-Object -Properties "MachineName",
                "CatalogName",
                "DesktopGroupName",
                "AssignedUserName" |
  Export-Csv -Path ".\CitrixUserAssignments.csv" -NoTypeInformation


<#
MachineName,CatalogName,DesktopGroupName,AssignedUserName
XD-VM01,Win11Persistent,FinanceGroup,user1@domain.com
XD-VM02,Win11Persistent,FinanceGroup,user2@domain.com
#>
