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
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import the shared functions
$LogPath = "$Env:ProgramData\ImageBuild"
Import-Module -Name "$LogPath\Functions.psm1" -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $LogPath\Functions.psm1"

#region Script logic
# Determine whether we should install with shared computer licensing
switch -Regex ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption) {
    #region Windows Server
    "Microsoft Windows Server*" {
        Write-LogFile -Message "Running on Windows Server, setting SharedComputerLicensing to 1"
        $SharedComputerLicensing = 1
        break
    }
    #endregion

    #region Windows 10/11 multi-session
    "Microsoft Windows 10 Enterprise for Virtual Desktops|Microsoft Windows 11 Enterprise multi-session" {
        Write-LogFile -Message "Running on Windows 10/11 multi-session, setting SharedComputerLicensing to 1"
        $SharedComputerLicensing = 1
        break
    }
    #endregion

    #region Windows 10
    "Microsoft Windows 1* Enterprise*|Microsoft Windows 1* Pro*" {
        Write-LogFile -Message "Running on Windows 10/11, setting SharedComputerLicensing to 0"
        $SharedComputerLicensing = 0
        break
    }
    #endregion

    default {
        Write-LogFile -Message "Using default SharedComputerLicensing value of 1"
        $SharedComputerLicensing = 1
    }
}

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    $Channel = "MonthlyEnterprise" # Default channel if no secure variable is set
    $OfficeXml = @"
<Configuration ID="5028b46a-6503-420f-89ad-46d51283eaf6">
  <Info Description="Microsoft 365 Apps for enterprise 64-bit including Microsoft Word, Excel, PowerPoint, Outlook, OneNote, OneDrive, Teams." />
  <Add OfficeClientEdition="64" Channel="MonthlyEnterprise" MigrateArch="TRUE">
    <Product ID="O365ProPlusRetail">
      <Language ID="MatchOS" />
      <Language ID="MatchPreviousMSI" />
      <ExcludeApp ID="Access" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="OutlookForWindows" />
      <ExcludeApp ID="Publisher" />
      <ExcludeApp ID="Lync" />
      <ExcludeApp ID="Bing" />
    </Product>
  </Add>
  <Property Name="SharedComputerLicensing" Value="$SharedComputerLicensing" />
  <Property Name="FORCEAPPSHUTDOWN" Value="FALSE" />
  <Property Name="DeviceBasedLicensing" Value="0" />
  <Property Name="SCLCacheOverride" Value="0" />
  <Updates Enabled="FALSE" />
  <RemoveMSI />
  <AppSettings>
    <User Key="software\microsoft\office\16.0\common\toolbars" Name="customuiroaming" Value="1" Type="REG_DWORD" App="office16" Id="L_AllowRoamingQuickAccessToolBarRibbonCustomizations" />
    <User Key="software\microsoft\office\16.0\common\general" Name="shownfirstrunoptin" Value="1" Type="REG_DWORD" App="office16" Id="L_DisableOptinWizard" />
    <User Key="software\microsoft\office\16.0\common\languageresources" Name="installlanguage" Value="3081" Type="REG_DWORD" App="office16" Id="L_PrimaryEditingLanguage" />
    <User Key="software\microsoft\office\16.0\common\fileio" Name="disablelongtermcaching" Value="0" Type="REG_DWORD" App="office16" Id="L_DeleteFilesFromOfficeDocumentCache" />
    <User Key="software\microsoft\office\16.0\common\general" Name="disablebackgrounds" Value="0" Type="REG_DWORD" App="office16" Id="L_DisableBackgrounds" />
    <User Key="software\microsoft\office\16.0\firstrun" Name="disablemovie" Value="1" Type="REG_DWORD" App="office16" Id="L_DisableMovie" />
    <User Key="software\microsoft\office\16.0\firstrun" Name="bootedrtm" Value="1" Type="REG_DWORD" App="office16" Id="L_DisableOfficeFirstrun" />
    <User Key="software\microsoft\office\16.0\common" Name="default ui theme" Value="0" Type="REG_DWORD" App="office16" Id="L_DefaultUIThemeUser" />
    <User Key="software\microsoft\office\16.0\excel\options" Name="defaultformat" Value="51" Type="REG_DWORD" App="excel16" Id="L_SaveExcelfilesas" />
    <User Key="software\microsoft\office\16.0\onenote\options\other" Name="runsystemtrayapp" Value="0" Type="REG_DWORD" App="onent16" Id="L_AddOneNoteicontonotificationarea" />
    <User Key="software\microsoft\office\16.0\outlook\preferences" Name="disablemanualarchive" Value="1" Type="REG_DWORD" App="outlk16" Id="L_DisableFileArchive" />
    <User Key="software\microsoft\office\16.0\outlook\autodiscover" Name="zeroconfigexchange" Value="1" Type="REG_DWORD" App="outlk16" Id="L_AutomaticallyConfigureProfileBasedOnActive" />
    <User Key="software\microsoft\office\16.0\outlook\options\rss" Name="disable" Value="1" Type="REG_DWORD" App="outlk16" Id="L_TurnoffRSSfeature" />
    <User Key="software\microsoft\office\16.0\outlook\setup" Name="disableroamingsettings" Value="0" Type="REG_DWORD" App="outlk16" Id="L_DisableRoamingSettings" />
    <User Key="software\microsoft\office\16.0\powerpoint\options" Name="defaultformat" Value="27" Type="REG_DWORD" App="ppt16" Id="L_SavePowerPointfilesas" />
    <User Key="software\microsoft\office\16.0\word\options" Name="defaultformat" Value="" Type="REG_SZ" App="word16" Id="L_SaveWordfilesas" />
  </AppSettings>
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
"@    
}
else {
    $Variables = Get-NerdioVariablesList
    $Channel = $Variables.$AzureRegionName.Microsoft365AppsChannel
    Write-LogFile -Message "Using configuration file from: $($Variables.$AzureRegionName.Microsoft365AppsConfig)"
    $params = @{
        Uri             = $Variables.$AzureRegionName.Microsoft365AppsConfig
        ContentType     = "text/xml"
        UseBasicParsing = $true
        ErrorAction     = "Stop"
    }
    $OfficeXml = (Invoke-WebRequest @params).Content
}

$XmlFile = Join-Path -Path $Path -ChildPath "Office.xml"
Write-LogFile -Message "Writing configuration to: $XmlFile"
Out-File -FilePath $XmlFile -InputObject $OfficeXml -Encoding "utf8"
#endregion

# Get Office version and download
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "Microsoft365Apps" | Where-Object { $_.Channel -eq $Channel } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
Write-LogFile -Message "Downloaded Microsoft 365 Apps setup to: $($OutFile.FullName)"

# Install package
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/configure $XmlFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Push-Location -Path $Path
Write-LogFile -Message "Installing Microsoft 365 Apps with: $($OutFile.FullName) $($params.ArgumentList)"
Start-Process @params
Pop-Location
#endregion
