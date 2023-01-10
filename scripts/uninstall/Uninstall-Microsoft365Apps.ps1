#description: Uninstalls the Microsoft 365 Apps
#execution mode: Combined
#tags: Evergreen, Uninstall, Microsoft, Microsoft 365 Apps
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\Office"

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
    throw $_.Exception.Message
}

try {
    # Get Office version and download
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "Microsoft365Apps" | Where-Object { $_.Channel -eq $Channel } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
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
    $result = Start-Process @params
    $result.ExitCode
    Pop-Location
}
catch {
    throw $_
}
finally {
    Pop-Location
    if ($result.ExitCode -eq 0) {
        if (Test-Path -Path $Path) { Remove-Item -Path $Path -Recurse -Force -ErrorAction "Ignore" }
    }
}
#endregion
