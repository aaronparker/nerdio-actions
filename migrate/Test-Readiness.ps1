[CmdletBinding(SupportsShouldProcess = $false)]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [System.String[]] $Publishers = @("Citrix*", "uberAgent*", "UniDesk*", "Omnissa*"),

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter] $IgnoreClientApp
)

begin {
    # Configure the environment
    $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
    $InformationPreference = [System.Management.Automation.ActionPreference]::Continue
    $ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue

    # Services that are part of the Citrix Workspace App or the Omnissa Horizon Client
    $ClientAppServices = @("CtxAdpPolicy", "CtxPkm", "CWAUpdaterService", "client_service",
        "ftnlsv3hv", "ftscanmgrhv", "hznsprrdpwks", "omnKsmNotifier", "ws1etlm")

    # Supported Windows versions (language-independent)
    # ProductType: 1 = Workstation, 2 = Domain Controller, 3 = Server
    # OperatingSystemSKU values for Enterprise and multi-session editions
    $SupportedVersions = @{
        # Windows 11 (Build 22000+)
        "11_Workstation" = @{
            BuildMin    = 22000
            ProductType = 1
            SKUs        = @(4, 125)  # 4 = Enterprise, 125 = Enterprise multi-session
        }
        # Windows 10 (Build 10240-22000)
        "10_Workstation" = @{
            BuildMin    = 10240
            BuildMax    = 21999
            ProductType = 1
            SKUs        = @(4, 125)  # 4 = Enterprise, 125 = Enterprise multi-session
        }
        # Windows Server 2025 (Build 26100+)
        "Server_2025"    = @{
            BuildMin    = 26100
            ProductType = 3
            SKUs        = @(7, 8)  # 7 = Standard, 8 = Datacenter
        }
        # Windows Server 2022 (Build 20348)
        "Server_2022"    = @{
            BuildMin    = 20348
            BuildMax    = 26099
            ProductType = 3
            SKUs        = @(7, 8)  # 7 = Standard, 8 = Datacenter
        }
        # Windows Server 2019 (Build 17763)
        "Server_2019"    = @{
            BuildMin    = 17763
            BuildMax    = 20347
            ProductType = 3
            SKUs        = @(7, 8)  # 7 = Standard, 8 = Datacenter
        }
        # Windows Server 2016 (Build 14393)
        "Server_2016"    = @{
            BuildMin    = 14393
            BuildMax    = 17762
            ProductType = 3
            SKUs        = @(7, 8)  # 7 = Standard, 8 = Datacenter
        }
    }
}

process {
    # Check if OS is 64-bit
    if ($Env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
        throw "Windows OS is not 64-bit."
    }

    # Get OS information using language-independent properties
    $OS = Get-CimInstance -ClassName "Win32_OperatingSystem"
    $BuildNumber = [System.Int32]$OS.BuildNumber
    $ProductType = $OS.ProductType
    $SKU = $OS.OperatingSystemSKU
    $Caption = $OS.Caption  # For display purposes only

    # Check if OS is supported
    $IsSupported = $false

    foreach ($Version in $SupportedVersions.GetEnumerator()) {
        $Config = $Version.Value
        
        # Check ProductType matches
        if ($ProductType -ne $Config.ProductType) {
            continue
        }
        
        # Check build number is within range
        $BuildInRange = $BuildNumber -ge $Config.BuildMin
        if ($Config.ContainsKey("BuildMax")) {
            $BuildInRange = $BuildInRange -and ($BuildNumber -le $Config.BuildMax)
        }
        
        if (-not $BuildInRange) {
            continue
        }
        
        # Check SKU matches (if SKU is available and valid)
        if ($SKU -gt 0 -and $Config.SKUs -contains $SKU) {
            $IsSupported = $true
            break
        }
    }

    if ($IsSupported) {
        Write-Information -MessageData "Windows OS is supported: $Caption (Build: $BuildNumber, SKU: $SKU, Type: $ProductType)."
    }
    else {
        throw "Windows OS is not supported: $Caption (Build: $BuildNumber, SKU: $SKU, Type: $ProductType)."
    }

    # Check if any of the specified 3rd party agents are installed by looking for their services
    $Services = Get-Service -DisplayName $Publishers

    # Filter out Citrix Workspace App services or the Omnissa Horizon Client if requested
    if ($IgnoreClientApp) {
        $Services = $Services | Where-Object { $_.Name -notin $ClientAppServices }
    }

    # If no services are found, return 0; otherwise, return 1
    if ($Services.Count -ge 1) {
        throw "Conflicting 3rd party agents found: $($Services.DisplayName -join ', ')."
    }
    else {
        Write-Information -MessageData "No conflicting 3rd party agents found."
        exit 0
    }
}
