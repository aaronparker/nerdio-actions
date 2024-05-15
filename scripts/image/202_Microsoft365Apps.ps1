<#
.SYNOPSIS
Installs the latest Microsoft 365 Apps for Enterprise with specific configurations.

.DESCRIPTION
This script installs the latest version of Microsoft 365 Apps for Enterprise with specific configurations.
It determines whether to install with shared computer licensing based on the operating system.
It also supports using secure variables in Nerdio Manager to pass a JSON file with the variables list for customization.

.PARAMETER Path
Specifies the download path for Microsoft 365 Apps. The default path is "$Env:SystemDrive\Apps\Microsoft\Office".

.NOTES
- This script requires the Evergreen module.
- This script requires administrative privileges to install Microsoft 365 Apps.
- This script supports Windows Server, Windows 10, and Windows 11 Enterprise multi-session.
- This script supports customization using a JSON file with secure variables in Nerdio Manager.
#>

#description: Installs the latest Microsoft 365 Apps for Enterprise, Current channel, 64-bit with shared computer licensing and updates disabled
#execution mode: Combined
#tags: Evergreen, Microsoft, Microsoft 365 Apps
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Office"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Determine whether we should install with shared computer licensing
switch -Regex ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption) {
    #region Windows Server
    "Microsoft Windows Server*" {
        $SharedComputerLicensing = 1
        break
    }
    #endregion

    #region Windows 10/11 multi-session
    "Microsoft Windows 10 Enterprise for Virtual Desktops|Microsoft Windows 11 Enterprise multi-session" {
        $SharedComputerLicensing = 1
        break
    }
    #endregion

    #region Windows 10
    "Microsoft Windows 1* Enterprise*|Microsoft Windows 1* Pro*" {
        $SharedComputerLicensing = 0
        break
    }
    #endregion

    default {
        $SharedComputerLicensing = 1
    }
}

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    #[ValidateSet("BetaChannel", "CurrentPreview", "Current", "MonthlyEnterprise", "PerpetualVL2021", "SemiAnnualPreview", "SemiAnnual", "PerpetualVL2019")]
    [System.String] $Channel = "MonthlyEnterprise"
    $OfficeXml = Get-Content -Path $Env:OfficeConfig
}
else {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $params = @{
        Uri             = $SecureVars.VariablesList
        UseBasicParsing = $true
        ErrorAction     = "Stop"
    }
    $Variables = Invoke-RestMethod @params
    [System.String] $Channel = $Variables.$AzureRegionName.Microsoft365AppsChannel
    $params = @{
        Uri             = $Variables.$AzureRegionName.Microsoft365AppsConfig
        ContentType     = "text/xml"
        UseBasicParsing = $true
        ErrorAction     = "Stop"
    }
    $OfficeXml = (Invoke-WebRequest @params).Content 
}

$XmlFile = Join-Path -Path $Path -ChildPath "Office.xml"
Out-File -FilePath $XmlFile -InputObject $OfficeXml -Encoding "utf8"
#endregion

# Get Office version and download
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "Microsoft365Apps" | Where-Object { $_.Channel -eq $Channel } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

# Install package
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/configure $XmlFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Continue"
}
Push-Location -Path $Path
Start-Process @params
Pop-Location
#endregion
