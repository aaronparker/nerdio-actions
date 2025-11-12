#description: Configures authentication to an Azure storage account for FSLogix profiles, for Entra ID only environments
#execution mode: Combined
#tags: FSLogix, Storage Account

#region Use Secure variables in Nerdio Manager to pass credentials
if ($null -eq $SecureVars.HostPoolStorageAuth) {
    throw "Host pool storage auth not specified"
}
#endregion

#region Configure access to the FSLogix storage account
try {
    # Gather details from JSON file
    $Json = $SecureVars.HostPoolStorageAuth | ConvertFrom-Json -ErrorAction "Stop"

    # Store credentials to access the storage account
    & "$Env:SystemRoot\System32\cmdkey.exe" /add:$($Json.$HostPoolName.FileServer) /user:$($Json.$HostPoolName.User) /pass:$($Json.$HostPoolName.Secret)

    # Disable Windows Defender Credential Guard (required for Windows 11 22H2)
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LsaCfgFlags" /d 0 /t "REG_DWORD" /f | Out-Null
}
catch {
    throw $_
}
#endregion
