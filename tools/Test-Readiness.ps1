[CmdletBinding(SupportsShouldProcess = $false)]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [System.String[]] $Publishers = @("Citrix*", "uberAgent*", "UniDesk*", "Omnissa*"),

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter] $IgnoreClientApp,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter] $IgnoreOmnissaHorizonClient
)

begin {
    # Services that are part of the Citrix Workspace App or the Omnissa Horizon Client
    $ClientAppServices = @("CtxAdpPolicy", "CtxPkm", "CWAUpdaterService", "client_service",
        "ftnlsv3hv", "ftscanmgrhv", "hznsprrdpwks", "omnKsmNotifier", "ws1etlm")

    # Supported Windows versions
    $SupportedVersions = @(
        "Windows 11 Enterprise",
        "Windows 11 Enterprise multi-session",
        "Windows 10 Enterprise",
        "Windows 10 Enterprise multi-session",
        "Windows Server 2025 Datacenter",
        "Windows Server 2025 Standard",
        "Windows Server 2022 Datacenter",
        "Windows Server 2022 Standard",
        "Windows Server 2019 Datacenter",
        "Windows Server 2019 Standard",
        "Windows Server 2016 Datacenter",
        "Windows Server 2016 Standard"
    )
}

process {
    # Check if OS is 64-bit
    if ($Env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
        Write-Error -Message "Windows OS is not 64-bit."
        return 1
    }

    # Get OS information
    $Caption = (Get-CimInstance -ClassName "Win32_OperatingSystem").Caption
    # Check if OS is supported
    if ($SupportedVersions -contains $Caption) {
        Write-Host "Windows OS is supported."
    }
    else {
        Write-Error -Message "Windows OS is not supported."
        return 1
    }

    # Check if any of the specified 3rd party agents are installed by looking for their services
    $Services = Get-Service -DisplayName $Publishers

    # Filter out Citrix Workspace App services or the Omnissa Horizon Client if requested
    if ($IgnoreClientApp) {
        $Services = $Services | Where-Object { $_.Name -notin $ClientAppServices }
    }

    # If no services are found, return 0; otherwise, return 1
    if ($Services.Count -ge 1) {
        return 1
    }
    else {
        return 0
    }
}
