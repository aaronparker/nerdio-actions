function Get-InstalledSoftware {
    $PropertyNames = "DisplayName", "DisplayVersion", "Publisher", "UninstallString", "PSPath", "WindowsInstaller",
    "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize", "SystemComponent"
    ("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*") | `
        ForEach-Object {
        Get-ItemProperty -Path $_ -Name $PropertyNames -ErrorAction "SilentlyContinue" | `
            . { process { if ($null -ne $_.DisplayName) { $_ } } } | `
            Where-Object { $_.SystemComponent -ne 1 } | `
            Select-Object -Property @{n = "Name"; e = { $_.DisplayName } }, @{n = "Version"; e = { $_.DisplayVersion } }, "Publisher",
        "UninstallString", @{n = "RegistryPath"; e = { $_.PSPath -replace "Microsoft.PowerShell.Core\\Registry::", "" } },
        "PSChildName", "WindowsInstaller", "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize" | `
            Sort-Object -Property "Name", "Publisher"
    }
}

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
        $Context.Log("Installing Microsoft Teams via dism")
        $Context.Log("Using attached binary: $($Context.GetAttachedBinary())")
        $params = @{
            FilePath     = "$Env:SystemRoot\System32\dism.exe"
            ArgumentList = "/Online /Add-ProvisionedAppxPackage /PackagePath:`"$($Context.GetAttachedBinary())`" /SkipLicense"
            Wait         = $true
            PassThru     = $true
            NoNewWindow  = $true
            ErrorAction  = "Stop"
        }
        $result = Start-Process @params
        $Context.Log("Install complete. Return code: $($result.ExitCode)")
    }

    "Microsoft Windows 11 Enterprise*|Microsoft Windows 11 Pro*|Microsoft Windows 10 Enterprise*|Microsoft Windows 10 Pro*" {
        $Context.Log("Installing Microsoft Teams on Windows 10/11")
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

        $Context.Log("Installing Microsoft Teams via bootstrapper: $TeamsExe")
        $Context.Log("Using attached binary: $($Context.GetAttachedBinary())")
        $params = @{
            FilePath     = $TeamsExe
            ArgumentList = "-p -o `"$($Context.GetAttachedBinary())`""
            Wait         = $true
            PassThru     = $true
            NoNewWindow  = $true
            ErrorAction  = "Stop"
        }
        $result = Start-Process @params
        $Context.Log("Install complete. Return code: $($result.ExitCode)")
    }
}

# Disable auto-update
$Context.Log("Add: HKLM\SOFTWARE\Microsoft\Teams\DisableAutoUpdate")
reg add "HKLM\SOFTWARE\Microsoft\Teams" /v "DisableAutoUpdate" /d 1 /t "REG_DWORD" /f | Out-Null

# Get the add-in path and version. Let's assume the Teams install has been successful
$TeamsPath = Get-AppxPackage | Where-Object { $_.PackageFamilyName -eq "MSTeams_8wekyb3d8bbwe" } | Select-Object -ExpandProperty "InstallLocation"
if ($TeamsPath) {
    $Context.Log("Found Teams install location: $TeamsPath.")
    $AddInInstallerPath = Get-ChildItem -Path $TeamsPath -Recurse -Include "MicrosoftTeamsMeetingAddinInstaller.msi" | Select-Object -ExpandProperty "FullName"
    $Context.Log("Found Teams Meeting Add-in installer: $AddInInstallerPath.")
    $Version = Get-AppLockerFileInformation -Path $AddInInstallerPath | Select-Object -ExpandProperty "Publisher"
    $AddInPath = "${Env:ProgramFiles(x86)}\Microsoft\TeamsMeetingAddin\$($Version.BinaryVersion.ToString())"
    $Context.Log("Teams Meeting Add-in path: $AddInPath")
}
else {
    $Context.Log("Teams Meeting Add-in not found.")
}

# Uninstall the old add-in if it's installed
Get-InstalledSoftware | Where-Object { $_.Name -match "Microsoft Teams Meeting Add-in*" } | ForEach-Object {
    $Context.Log("Uninstalling previous version of Microsoft Teams Meeting Add-in: $($_.PSChildName)")
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/uninstall `"$($_.PSChildName)`" /quiet /norestart"
        Wait         = $true
        PassThru     = $true
        NoNewWindow  = $true
        ErrorAction  = "Stop"
    }
    $result = Start-Process @params
    $Context.Log("Uninstall complete. Return code: $($result.ExitCode)")
}

# Install the new version of the add-in
if ($AddInInstallerPath) {
    $Context.Log("Installing Microsoft Teams Meeting Add-in from: $AddInInstallerPath")
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$AddInInstallerPath`" ALLUSERS=1 TARGETDIR=`"$AddInPath`" /quiet /norestart"
        Wait         = $true
        PassThru     = $true
        NoNewWindow  = $true
        ErrorAction  = "Stop"
    }
    $result = Start-Process @params
    $Context.Log("Install complete. Return code: $($result.ExitCode)")
}
else {
    $Context.Log("No Teams Meeting Add-in installer found. Skipping installation.")
}