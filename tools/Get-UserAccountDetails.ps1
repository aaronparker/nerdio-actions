<#
    Return details about the local system and last logged on user, including UPN and account provider if available.
#>

# Interesting registry keys
# "HKLM:\SOFTWARE\Microsoft\Enrollments"
# "HKLM:\SOFTWARE\Microsoft\IdentityStore\Cache"
# "HKLM:\SOFTWARE\Microsoft\IdentityStore\LogonCache"
# "HKLM:\SYSTEM\ControlSet001\Control\CloudDomainJoin\JoinInfo"

# Configure the environment
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
$InformationPreference = [System.Management.Automation.ActionPreference]::Continue
$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

# Get details about the last logged on user
$Properties = "LastLoggedOnDisplayName",
"LastLoggedOnSAMUser",
"LastLoggedOnUser",
"LastLoggedOnUserSID",
"SelectedUserSID"
$LastLoggedOnUser = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" | Select-Object -Property $Properties

# Get details about all user profiles on the system, excluding system profiles (S-1-5-18, S-1-5-19, S-1-5-20)
$Profiles = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Where-Object { $_ -notmatch "S-1-5-(18|19|20)$" }
$ProfilesList = foreach ($Item in $Profiles) {
    $ProfilePath = Get-ItemPropertyValue -Path $Item.PSPath -Name "ProfileImagePath"
    $Low = Get-ItemPropertyValue -Path $Item.PSPath -Name "LocalProfileLoadTimeLow"
    $High = Get-ItemPropertyValue -Path $Item.PSPath -Name "LocalProfileLoadTimeHigh"
    $Filetime = ([UInt64]$High -shl 32) -bor $Low # Combine high and low parts into a 64-bit FILETIME
    $LastLoggedOnDate = [System.DateTime]::FromFileTime($Filetime) # Convert to DateTime
    [PSCustomObject]@{
        SID              = $Item.PSPath.Split('\')[-1]
        ProfilePath      = $ProfilePath
        LastLoggedOnDate = $LastLoggedOnDate.ToUniversalTime().ToString("o")
    }
}

# Get details about the identity store for the last logged on user
$IdentityStore = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\IdentityStore\Cache\$($LastLoggedOnUser.SelectedUserSID)\IdentityCache\$($LastLoggedOnUser.SelectedUserSID)"

# Output the results
[PSCustomObject]@{
    ComputerName        = [System.Net.Dns]::GetHostName()
    UserPrincipalName   = $IdentityStore.UserName
    UserAccountProvider = $IdentityStore.ProviderName
    LastLoggedOnUser    = $LastLoggedOnUser
    ProfilesList        = $ProfilesList
} | ConvertTo-Json -Depth 10
