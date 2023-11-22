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
    $OfficeXml = @"
    <Configuration ID="a39b1c70-558d-463b-b3d4-9156ddbcbb05">
        <Add OfficeClientEdition="64" Channel="$Channel" MigrateArch="TRUE">
            <Product ID="O365ProPlusRetail">
                <Language ID="MatchOS" />
                <Language ID="MatchPreviousMSI" />
                <ExcludeApp ID="Access" />
                <ExcludeApp ID="Groove" />
                <ExcludeApp ID="Lync" />
                <ExcludeApp ID="Publisher" />
                <ExcludeApp ID="Bing" />
                <ExcludeApp ID="Teams" />
                <ExcludeApp ID="OneDrive" />
            </Product>
        </Add>
        <Property Name="SharedComputerLicensing" Value="$SharedComputerLicensing" />
        <Property Name="PinIconsToTaskbar" Value="FALSE" />
        <Property Name="SCLCacheOverride" Value="0" />
        <Property Name="AUTOACTIVATE" Value="0" />
        <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
        <Property Name="DeviceBasedLicensing" Value="0" />
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
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $params = @{
            Uri             = $SecureVars.VariablesList
            UseBasicParsing = $true
            ErrorAction     = "Stop"
        }
        $Variables = Invoke-RestMethod @params
        [System.String] $Channel = $Variables.$AzureRegionName.M365Channel
        $params = @{
            Uri             = $Variables.$AzureRegionName.M365AppsConfig
            ContentType     = "text/xml"
            UseBasicParsing = $true
            ErrorAction     = "Stop"
        }
        $OfficeXml = (Invoke-WebRequest @params).Content 
        $XmlFile = Join-Path -Path $Path -ChildPath "Office.xml"
        Out-File -FilePath $XmlFile -InputObject $OfficeXml -Encoding "utf8"
    }
    catch {
        throw $_
    }
}
#endregion

try {
    # Get Office version and download
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "Microsoft365Apps" | Where-Object { $_.Channel -eq $Channel } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    # Install package
    Write-Information -MessageData ":: Install Microsoft 365 Apps" -InformationAction "Continue"
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = "/configure $XmlFile"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    Push-Location -Path $Path
    $result = Start-Process @params
    Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
    Pop-Location
}
catch {
    throw $_
}
finally {
    Pop-Location
}
#endregion
