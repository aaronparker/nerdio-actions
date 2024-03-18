<#
.SYNOPSIS
Installs the latest Microsoft Teams v2 per-machine for use on Windows 10/11 multi-session or Windows Server.

.DESCRIPTION
This script installs the latest version of Microsoft Teams v2 per-machine.
It downloads the Teams v2 Bootstrap installer and the Teams v2 MSIX installer from the specified URIs and installs them based on the operating system.
It also sets the required registry value for IsWVDEnvironment and optimizes Teams by disabling auto-update and installing the Teams meeting add-in.

.PARAMETER Path
The path where Microsoft Teams will be downloaded. The default path is "$Env:SystemDrive\Apps\Microsoft\Teams".

.NOTES
- This script requires the Evergreen module.
- Secure variables can be used to pass a JSON file with the variables list.
- The script supports Windows 10/11 multi-session and Windows Server.

#region Optimise Teams
# Autostart
# HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MSTeams_8wekyb3d8bbwe\TeamsTfwStartupTask
# State
# 2,1

# %LocalAppData%\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\app_settings.json
# "open_app_in_background":true
# "language": "en-AU"
#>

#execution mode: Combined
#tags: Evergreen, Microsoft, Teams, per-machine
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Teams"

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    [System.String] $Language = "en-AU"
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
        [System.String] $Language = $Variables.$AzureRegionName.Language
    }
    catch {
        throw $_
    }
}
#endregion

#region Functions
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
                . { process { if ($Null -ne $_.DisplayName) { $_ } } } | `
                Where-Object { $_.SystemComponent -ne 1 } | `
                Select-Object -Property @{n = "Name"; e = { $_.DisplayName } }, @{n = "Version"; e = { $_.DisplayVersion } }, "Publisher", "UninstallString", @{n = "RegistryPath"; e = { $_.PSPath -replace "Microsoft.PowerShell.Core\\Registry::", "" } }, "PSChildName", "WindowsInstaller", "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize" | `
                Sort-Object -Property "DisplayName", "Publisher"
        }
        catch {
            throw $_
        }
    }
    return $Apps
}
#endregion

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Download Teams v2 Bootstrap installer
$App = [PSCustomObject]@{
    Version = "2.0.0"
    URI     = "https://statics.teams.cdn.office.net/production-teamsprovision/lkg/teamsbootstrapper.exe"
}
$TeamsExe = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

# Download Teams v2 MSIX installer
$App = [PSCustomObject]@{
    Version = "2.0.0"
    URI     = "https://statics.teams.cdn.office.net/production-windows-x64/enterprise/webview2/lkg/MSTeams-x64.msix"
}
$TeamsMsix = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

# Remove any existing Teams AppX package
Get-AppxPackage | Where-Object { $_.PackageFamilyName -eq "MSTeams_8wekyb3d8bbwe" } | Remove-AppxPackage -ErrorAction "SilentlyContinue"

# Install Teams
Write-Information -MessageData ":: Install Microsoft Teams" -InformationAction "Continue"

# Set required IsWVDEnvironment registry value
reg add "HKLM\SOFTWARE\Microsoft\Teams" /v "IsWVDEnvironment" /d 1 /t "REG_DWORD" /f | Out-Null

# Install steps based on the OS we're running on
switch -Regex ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption) {
    "Microsoft Windows Server*" {
        $params = @{
            FilePath     = "$Env:SystemRoot\System32\dism.exe"
            ArgumentList = "/Online /Add-ProvisionedAppxPackage /PackagePath:`"$($TeamsMsix.FullName)`" /SkipLicense"
            NoNewWindow  = $true
            Wait         = $true
            PassThru     = $true
            ErrorAction  = "Continue"
        }
        $result = Start-Process @params
        Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
    }

    "Microsoft Windows 11 Enterprise*|Microsoft Windows 11 Pro*|Microsoft Windows 10 Enterprise*|Microsoft Windows 10 Pro*" {
        $params = @{
            FilePath     = $TeamsExe.FullName
            ArgumentList = "-p -o `"$($TeamsMsix.FullName)`""
            NoNewWindow  = $true
            Wait         = $true
            PassThru     = $true
            ErrorAction  = "Continue"
        }
        $result = Start-Process @params
        Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
    }
}

# Disable auto-update
reg add "HKLM\SOFTWARE\Microsoft\Teams" /v "DisableAutoUpdate" /d 1 /t "REG_DWORD" /f | Out-Null

# Get the add-in path and version. Let's assume the Teams install has been successful
$TeamsPath = Get-AppxPackage | Where-Object { $_.PackageFamilyName -eq "MSTeams_8wekyb3d8bbwe" } | Select-Object -ExpandProperty "InstallLocation"
$AddInInstallerPath = Get-ChildItem -Path $TeamsPath -Recurse -Include "MicrosoftTeamsMeetingAddinInstaller.msi" | Select-Object -ExpandProperty "FullName"
$Version = Get-AppLockerFileInformation -Path $AddInInstallerPath | Select-Object -ExpandProperty "Publisher"
$AddInPath = "${Env:ProgramFiles(x86)}\Microsoft\TeamsMeetingAddin\$($Version.BinaryVersion.ToString())"

# Uninstall the old add-in if it's installed
$PreviousInstall = Get-InstalledSoftware | Where-Object { $_.Name -match "Microsoft Teams Meeting Add-in*" }
if ([System.String]::IsNullOrEmpty($PreviousInstall.PSChildName)) {}
else {
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/uninstall `"$($PreviousInstall.PSChildName)`" /quiet /norestart"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
}

# Install the new version of the add-in
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$AddInInstallerPath`" ALLUSERS=1 TARGETDIR=`"$AddInPath`" /quiet /norestart"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Continue"
}
$result = Start-Process @params
Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
#endregion
