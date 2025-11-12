#description: Enables Hybrid Azure AD join registry entries
#execution mode: Combined
#tags: Image, HAADJ

# https://learn.microsoft.com/en-us/azure/active-directory/devices/hybrid-azuread-join-control

if ($null -eq $SecureVars.AzureADTenantName) {
    throw "AzureADTenantName not set"
}

if ($null -eq $SecureVars.AzureADTenantId) {
    throw "AzureADTenantId not set"
}

# Add registry keys
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CDJ\AAD" /v "TenantName" /t "REG_SZ" /d $SecureVars.AzureADTenantName /f | Out-Null
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CDJ\AAD" /v "TenantId" /t "REG_SZ" /d $SecureVars.AzureADTenantId /f | Out-Null
