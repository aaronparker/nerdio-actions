[CmdletBinding(SupportsShouldProcess = $false)]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [System.String[]] $Publishers = @("Citrix*", "uberAgent*", "UniDesk*", "Omnissa*"),

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter] $IgnoreCitrixWorkspaceApp,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter] $IgnoreOmnissaHorizonClient
)

begin {
    # Services that are part of the Citrix Workspace App
    $CitrixWorkspaceAppServices = "CtxAdpPolicy", "CtxPkm", "CWAUpdaterService"

    # Services that are part of the Omnissa Horizon Client
    $OmnissaHorizonClientServices = "client_service", "ftnlsv3hv", "ftscanmgrhv", "hznsprrdpwks", "omnKsmNotifier", "ws1etlm"
}

process {
    # Check if any of the specified 3rd party agents are installed by looking for their services
    $Services = Get-Service -DisplayName $Publishers

    # Filter out Citrix Workspace App services if requested
    if ($IgnoreCitrixWorkspaceApp) {
        $Services = $Services | Where-Object { $_.Name -notin $CitrixWorkspaceAppServices }
    }

    # Filter out Omnissa Horizon Client services if requested
    if ($IgnoreOmnissaHorizonClient) {
        $Services = $Services | Where-Object { $_.Name -notin $OmnissaHorizonClientServices }
    }

    # If no services are found, return 0; otherwise, return 1
    if ($Services.Count -eq 0) {
        return 0
    }
    else {
        return 1
    }
}
