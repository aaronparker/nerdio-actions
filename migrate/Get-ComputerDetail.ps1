<#
    .SYNOPSIS
    Collects detailed identity, user profile, software, and operating system information from the local Windows computer and emits the data as JSON.

    .DESCRIPTION
    This script gathers a comprehensive set of attributes about the current machine and last logged-on user:

    - Identity and join status:
        - Azure AD (Entra ID) and domain join state via dsregcmd.exe /status.
    - Last logged-on user details:
        - Display name, SAM account, SID, and selected user SID from HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI.
    - User profiles:
        - Enumerates HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList, excluding system SIDs (S-1-5-18/19/20).
        - Produces a list of profiles with SID, profile path, and last logon timestamp (converted from FILETIME to ISO 8601 UTC).
    - Identity Store:
        - Reads provider and UPN for the selected user from HKLM:\SOFTWARE\Microsoft\IdentityStore\Cache.
    - Installed software:
        - Queries 64-bit and 32-bit uninstall registry hives, normalizes output, and filters out system components.
        - Produces name, version, and publisher for installed applications.
    - Source tagging:
        - Detects presence of specific third-party agents and tags the source:
            - Citrix: *Virtual Delivery Agent
            - Omnissa (VMware): *Horizon Agent
            - Parallels: *RAS Guest Agent
    - Operating system info:
        - Retrieves key properties from Win32_OperatingSystem (Caption, BuildNumber, OperatingSystemSKU, ProductType, MUILanguages).

    The script outputs a single JSON string representing a structured object with the following properties:
    - ComputerName: string
    - EntraIdJoined: bool
    - DomainJoined: bool
    - UserPrincipalName: string
    - UserAccountProvider: string
    - LastLoggedOnUser: object (Display/SAM/SID properties from LogonUI)
    - ProfilesList: array of objects (SID, ProfilePath, LastLoggedOnDate)
    - Source: object (Name, Version, Publisher, Tag) for matched agent, if present
    - InstalledSoftware: array of objects (Name, Version, Publisher)
    - OSInfo: object (selected Win32_OperatingSystem properties)

    .PARAMETER None
    This script takes no parameters.

    .INPUTS
    None. Pipeline input is not accepted.

    .OUTPUTS
    System.String
    A JSON string with depth up to 10 representing the collected system information.

    .EXAMPLE
    PS> .\Get-ComputerDetail.ps1 | ConvertFrom-Json
    Runs the script and converts the JSON output back into a PowerShell object for further processing.

    .EXAMPLE
    PS> .\Get-ComputerDetail.ps1 | Out-File -FilePath .\computer-details.json -Encoding utf8
    Captures the JSON output to a file.

    .NOTES
    - Requires Windows and access to:
        - dsregcmd.exe (typically in %SystemRoot%\System32).
        - HKLM registry hives referenced by the script.
    - Elevated privileges may be required to read certain registry keys reliably.
    - CmdletBinding SupportsShouldProcess is enabled, but the script is read-only and does not modify system state.
    - ErrorActionPreference is set to SilentlyContinue for registry reads; some keys may be missing on certain configurations.

    .LINK
    https://learn.microsoft.com/windows/security/identity-protection/azuread-joined-device/dsregcmd
    https://learn.microsoft.com/windows/win32/cimwin32prov/win32-operatingsystem
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param ()

begin {
    # Configure the environment
    $ErrorActionPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
    $InformationPreference = [System.Management.Automation.ActionPreference]::Continue

    # Define 3rd party publishers
    $Publishers = @{
        "Citrix"    = "*Virtual Delivery Agent"
        "Omnissa"   = "*Horizon Agent"
        "Parallels" = "*RAS Guest Agent"
    }

    # Define OS properties to retrieve from Win32_OperatingSystem
    $OSProperties = "Caption", "BuildNumber", "OperatingSystemSKU", "ProductType", "MUILanguages"

    #region functions
    function Get-DsRegStatus {
        $Output = & "$Env:SystemRoot\System32\dsregcmd.exe" /status | Out-String
        $DsRegTable = $Output -split "`n" | ForEach-Object {
            if ($_ -match "^(.*?):\s*(.*)$") {
                [PSCustomObject]@{
                    Key   = $matches[1].Trim()
                    Value = $matches[2].Trim()
                }
            }
        }
        $DsRegObject = [PSCustomObject]@{}
        foreach ($item in $DsRegTable) {
            switch ($item.Value) {
                "YES" { $item.Value = $true }
                "NO" { $item.Value = $false }
            }
            if ($item.Key -notlike "For more information*") {
                $DsRegObject | Add-Member -MemberType "NoteProperty" -Name ($item.Key -replace "\s+|-", "") -Value $item.Value
            }
        }
        return $DsRegObject
    }

    function Get-InstalledSoftware {
        $PropertyNames = "DisplayName", "DisplayVersion", "Publisher", "UninstallString", "PSPath", "WindowsInstaller",
        "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize", "SystemComponent"
        ("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*") | `
            ForEach-Object {
            Get-ItemProperty -Path $_ -Name $PropertyNames -ErrorAction "SilentlyContinue" | `
                . { process { if ($null -ne $_.DisplayName) { $_ } } } | `
                Where-Object { $_.SystemComponent -ne 1 } | `
                Select-Object -Property @{n = "Name"; e = { $_.DisplayName } }, @{n = "Version"; e = { $_.DisplayVersion } }, "Publisher",
            "UninstallString", @{n = "RegistryPath"; e = { $_.PSPath -replace "Microsoft.PowerShell.Core\\Registry::", "" } },
            "PSChildName", "WindowsInstaller", "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize" | `
                Sort-Object -Property "Name", "Publisher"
        }
    }
    #endregion
}

process {
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

    # Get details from DsRegCmd
    $DsRegStatus = Get-DsRegStatus

    # Create an object that identifes the source system
    $Source = Get-InstalledSoftware | Select-Object -Property "Name", "Version", "Publisher" | Where-Object {
        foreach ($Publisher in $Publishers.Keys) {
            foreach ($Pattern in $Publishers[$Publisher]) {
                if ($_.Name -like $Pattern -and $_.Publisher -like "$Publisher*" ) {
                    $_ | Add-Member -MemberType NoteProperty -Name "Tag" -Value $Publisher -Force
                    return $true
                }
            }
        }
        return $false
    }

    # Output the results
    [PSCustomObject]@{
        ComputerName        = [System.Net.Dns]::GetHostName()
        EntraIdJoined       = $DsRegStatus.AzureADJoined
        DomainJoined        = $DsRegStatus.DomainJoined
        UserPrincipalName   = $IdentityStore.UserName
        UserAccountProvider = $IdentityStore.ProviderName
        LastLoggedOnUser    = $LastLoggedOnUser
        ProfilesList         = $ProfilesList
        Source              = $Source
        InstalledSoftware   = (Get-InstalledSoftware | Select-Object -Property "Name", "Version", "Publisher")
        OSInfo              = Get-CimInstance -ClassName "Win32_OperatingSystem" | Select-Object -Property $OSProperties
    } | ConvertTo-Json -Depth 10 | Write-Output
}
