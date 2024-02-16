#description: Uninstalls the Microsoft 365 Apps
#execution mode: Combined
#tags: Evergreen, Uninstall, Microsoft, Microsoft 365 Apps
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Office"

[System.String] $Channel = "MonthlyEnterprise"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    # Set the Microsoft 365 Apps configuration
    $OfficeXml = @"
<Configuration>
    <Remove All="TRUE"/>
    <Display Level="None" AcceptEULA="TRUE"/>
    <Property Name="AUTOACTIVATE" Value="0"/>
    <Property Name="FORCEAPPSHUTDOWN" Value="TRUE"/>
    <Property Name="SharedComputerLicensing" Value="0"/>
    <Property Name="PinIconsToTaskbar" Value="FALSE"/>
</Configuration>
"@

    $XmlFile = Join-Path -Path $Path -ChildPath "Uninstall-Office.xml"
    Out-File -FilePath $XmlFile -InputObject $OfficeXml -Encoding "utf8"
}
catch {
    throw $_
}

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
$result = Start-Process @params
$result.ExitCode
#endregion
