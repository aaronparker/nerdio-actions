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

#description: Installs and optimises the latest Microsoft Teams 2.0 client
#execution mode: Combined
#tags: Evergreen, Microsoft, Teams, per-machine
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Teams"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

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
                Sort-Object -Property "Name", "Publisher"
        }
        catch {
            throw $_
        }
    }
    return $Apps
}
#endregion

#region Script logic
# Download Teams v2 Bootstrap installer
$App = [PSCustomObject]@{
    Version = "2.0.0"
    URI     = "https://statics.teams.cdn.office.net/production-teamsprovision/lkg/teamsbootstrapper.exe"
}
$TeamsExe = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
Write-LogFile -Message "Downloaded Microsoft Teams Bootstrapper to: $($TeamsExe.FullName)"

# Download Teams v2 MSIX installer
Write-LogFile -Message "Downloading Microsoft Teams v2 MSIX package"
$App = Get-EvergreenApp -Name "MicrosoftTeams" | `
    Where-Object { $_.Release -eq "Enterprise" -and $_.Architecture -eq "x64" }
$TeamsMsix = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
Write-LogFile -Message "Downloaded Microsoft Teams MSIX to: $($TeamsMsix.FullName)"

# Remove any existing Teams AppX package
Get-AppxPackage -AllUsers | Where-Object { $_.PackageFamilyName -eq "MSTeams_8wekyb3d8bbwe" } | ForEach-Object {
    Write-LogFile -Message "Removing existing Teams AppX package: $($_.Name)"
    $_ | Remove-AppxPackage -AllUsers -ErrorAction "SilentlyContinue"
}

# Install Teams
# Set required IsWVDEnvironment registry value
Write-LogFile -Message "Add: HKLM\SOFTWARE\Microsoft\Teams\IsWVDEnvironment"
reg add "HKLM\SOFTWARE\Microsoft\Teams" /v "IsWVDEnvironment" /d 1 /t "REG_DWORD" /f *> $null

# Install steps based on the OS we're running on
switch -Regex ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption) {
    "Microsoft Windows Server*" {
        Write-LogFile -Message "Installing Microsoft Teams on Windows Server"
        $params = @{
            FilePath     = "$Env:SystemRoot\System32\dism.exe"
            ArgumentList = "/Online /Add-ProvisionedAppxPackage /PackagePath:`"$($TeamsMsix.FullName)`" /SkipLicense"
        }
        Start-ProcessWithLog @params

        # Get the add-in path and version. Let's assume the Teams install has been successful
        $TeamsPath = Get-AppxPackage | Where-Object { $_.PackageFamilyName -eq "MSTeams_8wekyb3d8bbwe" } | Select-Object -ExpandProperty "InstallLocation"
        $AddInInstallerPath = Get-ChildItem -Path $TeamsPath -Recurse -Include "MicrosoftTeamsMeetingAddinInstaller.msi" | Select-Object -ExpandProperty "FullName"
        $Version = Get-AppLockerFileInformation -Path $AddInInstallerPath | Select-Object -ExpandProperty "Publisher"
        $AddInPath = "${Env:ProgramFiles(x86)}\Microsoft\TeamsMeetingAddin\$($Version.BinaryVersion.ToString())"
        Write-LogFile -Message "Teams Meeting Add-in path: $AddInPath"

        # Uninstall the old add-in if it's installed
        $PreviousInstall = Get-InstalledSoftware | Where-Object { $_.Name -match "Microsoft Teams Meeting Add-in*" }
        if ([System.String]::IsNullOrEmpty($PreviousInstall.PSChildName)) {}
        else {
            Write-LogFile -Message "Uninstalling previous version of Microsoft Teams Meeting Add-in: $($PreviousInstall.PSChildName)"
            $params = @{
                FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
                ArgumentList = "/uninstall `"$($PreviousInstall.PSChildName)`" /quiet /norestart"
            }
            Start-ProcessWithLog @params
        }

        # Install the new version of the add-in
        Write-LogFile -Message "Installing Microsoft Teams Meeting Add-in from: $AddInInstallerPath"
        $params = @{
            FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
            ArgumentList = "/package `"$AddInInstallerPath`" ALLUSERS=1 TARGETDIR=`"$AddInPath`" /quiet /norestart"
        }
        Start-ProcessWithLog @params
    }

    "Microsoft Windows 11 Enterprise*|Microsoft Windows 11 Pro*|Microsoft Windows 10 Enterprise*|Microsoft Windows 10 Pro*" {
        Write-LogFile -Message "Installing Microsoft Teams and Outlook meeting add-in on Windows 10/11"
        $params = @{
            FilePath     = $TeamsExe.FullName
            ArgumentList = "-p -o `"$($TeamsMsix.FullName)`" --installTMA"
        }
        Start-ProcessWithLog @params
    }
}

# Disable auto-update
Write-LogFile -Message "Add: HKLM\SOFTWARE\Microsoft\Teams\DisableAutoUpdate"
reg add "HKLM\SOFTWARE\Microsoft\Teams" /v "DisableAutoUpdate" /d 1 /t "REG_DWORD" /f | Out-Null
#endregion
