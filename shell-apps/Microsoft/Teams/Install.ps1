function Get-InstalledSoftware {
    [CmdletBinding()]
    param ()
    $UninstallKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $Apps = @()
    foreach ($Key in $UninstallKeys) {
        try {
            $propertyNames = "DisplayName", "DisplayVersion", "Publisher", "UninstallString", "PSPath", "WindowsInstaller", "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize", "SystemComponent"
            $Apps += Get-ItemProperty -Path $Key -Name $propertyNames -ErrorAction "SilentlyContinue" | `
                . { process { if ($null -ne $_.DisplayName) { $_ } } } | `
                Where-Object { $_.SystemComponent -ne 1 } | `
                Select-Object -Property @{n = "Name"; e = { $_.DisplayName } }, @{n = "Version"; e = { $_.DisplayVersion } }, "Publisher", "UninstallString", @{n = "RegistryPath"; e = { $_.PSPath -replace "Microsoft.PowerShell.Core\\Registry::", "" } }, "PSChildName", "WindowsInstaller", "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize" | `
                Sort-Object -Property "DisplayName", "Publisher"
        }
        catch {
            throw $_.Exception.Message
        }
    }
    return $Apps
}

# Download the Microsoft Teams Bootstrapper
$ProgressPreference = "SilentlyContinue"
$TeamsExe = "$PWD\teamsbootstrapper.exe"
$params = @{
    URI             = "https://statics.teams.cdn.office.net/production-teamsprovision/lkg/teamsbootstrapper.exe"
    OutFile         = $TeamsExe
    UseBasicParsing = $true
    ErrorAction     = "Stop"
}
Invoke-WebRequest @params
$Context.Log("Downloaded Microsoft Teams Bootstrapper to: $TeamsExe")

# Remove any existing Teams AppX package
Get-AppxPackage -AllUsers | Where-Object { $_.PackageFamilyName -eq "MSTeams_8wekyb3d8bbwe" } | ForEach-Object {
    $Context.Log("Removing existing Teams AppX package: $($_.Name)")
    $_ | Remove-AppxPackage -AllUsers -ErrorAction "SilentlyContinue"
}

# Install Teams
# Set required IsWVDEnvironment registry value
$Context.Log("Add: HKLM\SOFTWARE\Microsoft\Teams\IsWVDEnvironment")
reg add "HKLM\SOFTWARE\Microsoft\Teams" /v "IsWVDEnvironment" /d 1 /t "REG_DWORD" /f *> $null

# Install steps based on the OS we're running on
switch -Regex ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption) {
    "Microsoft Windows Server*" {
        $Context.Log("Installing Microsoft Teams on Windows Server")
        $params = @{
            FilePath     = "$Env:SystemRoot\System32\dism.exe"
            ArgumentList = "/Online /Add-ProvisionedAppxPackage /PackagePath:`"$($Context.GetAttachedBinary())`" /SkipLicense"
            Wait         = $true
            NoNewWindow  = $true
            ErrorAction  = "Stop"
        }
        Start-Process @params
    }

    "Microsoft Windows 11 Enterprise*|Microsoft Windows 11 Pro*|Microsoft Windows 10 Enterprise*|Microsoft Windows 10 Pro*" {
        $Context.Log("Installing Microsoft Teams on Windows 10/11")
        $params = @{
            FilePath     = $TeamsExe
            ArgumentList = "-p -o `"$($Context.GetAttachedBinary())`""
            Wait         = $true
            NoNewWindow  = $true
            ErrorAction  = "Stop"
        }
        Start-Process @params
    }
}

# Disable auto-update
$Context.Log("Add: HKLM\SOFTWARE\Microsoft\Teams\DisableAutoUpdate")
reg add "HKLM\SOFTWARE\Microsoft\Teams" /v "DisableAutoUpdate" /d 1 /t "REG_DWORD" /f | Out-Null

# Get the add-in path and version. Let's assume the Teams install has been successful
$TeamsPath = Get-AppxPackage | Where-Object { $_.PackageFamilyName -eq "MSTeams_8wekyb3d8bbwe" } | Select-Object -ExpandProperty "InstallLocation"
$AddInInstallerPath = Get-ChildItem -Path $TeamsPath -Recurse -Include "MicrosoftTeamsMeetingAddinInstaller.msi" | Select-Object -ExpandProperty "FullName"
$Version = Get-AppLockerFileInformation -Path $AddInInstallerPath | Select-Object -ExpandProperty "Publisher"
$AddInPath = "${Env:ProgramFiles(x86)}\Microsoft\TeamsMeetingAddin\$($Version.BinaryVersion.ToString())"
$Context.Log("Teams Meeting Add-in path: $AddInPath")

# Uninstall the old add-in if it's installed
$PreviousInstall = Get-InstalledSoftware | Where-Object { $_.Name -match "Microsoft Teams Meeting Add-in*" }
if ([System.String]::IsNullOrEmpty($PreviousInstall.PSChildName)) {}
else {
    $Context.Log("Uninstalling previous version of Microsoft Teams Meeting Add-in: $($PreviousInstall.PSChildName)")
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/uninstall `"$($PreviousInstall.PSChildName)`" /quiet /norestart"
        Wait         = $true
        NoNewWindow  = $true
        ErrorAction  = "Stop"
    }
    Start-Process @params
}

# Install the new version of the add-in
$Context.Log("Installing Microsoft Teams Meeting Add-in from: $AddInInstallerPath")
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$AddInInstallerPath`" ALLUSERS=1 TARGETDIR=`"$AddInPath`" /quiet /norestart"
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
Start-Process @params
