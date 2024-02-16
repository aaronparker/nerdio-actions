#description: Installs the latest Microsoft Teams v2 per-machine for use on Windows 10/11 multi-session or Windows Server
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

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

    # https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409
    # https://statics.teams.cdn.office.net/production-teamsprovision/lkg/teamsbootstrapper.exe

    # https://go.microsoft.com/fwlink/?linkid=2196106
    # https://statics.teams.cdn.office.net/production-windows-x64/enterprise/webview2/lkg/MSTeams-x64.msix

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
    $TeamsMsi = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

    # Set required IsWVDEnvironment registry value
    reg add "HKLM\SOFTWARE\Microsoft\Teams" /v "IsWVDEnvironment" /d 1 /t "REG_DWORD" /f | Out-Null

    # Install Teams
    Write-Information -MessageData ":: Install Microsoft Teams" -InformationAction "Continue"
    switch -Regex ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption) {
        "Microsoft Windows Server*" {
            $params = @{
                FilePath     = "$Env:SystemRoot\System32\dism.exe"
                ArgumentList = "/Online /Add-ProvisionedAppxPackage /PackagePath:`"$($TeamsMsi.FullName)`" /SkipLicense"
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
                ArgumentList = "-p -o `"$($TeamsMsi.FullName)`""
                NoNewWindow  = $true
                Wait         = $true
                PassThru     = $true
                ErrorAction  = "Continue"
            }
            $result = Start-Process @params
            Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
        }
    }
#endregion

#region Optimise Teams
# Autostart
# HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MSTeams_8wekyb3d8bbwe\TeamsTfwStartupTask
# State
# 2,1

# %LocalAppData%\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\app_settings.json
# "open_app_in_background":true
# "language": "en-AU"

# Disable auto-update
reg add "HKLM\SOFTWARE\Microsoft\Teams" /v "DisableAutoUpdate" /d 1 /t "REG_DWORD" /f | Out-Null

# Install Teams / Outlook meeting add-in
Write-Information -MessageData ":: Install Microsoft Teams meeting add-in" -InformationAction "Continue"

$TeamsPath = Get-ChildItem -Path "$Env:ProgramFiles\WindowsApps\MSTeams*" | Select-Object -ExpandProperty FullName | Sort-Object | Select-Object -First 1
$AddInInstaller = Get-ChildItem -Path $TeamsPath -Recurse -Include "MicrosoftTeamsMeetingAddinInstaller.msi"
$Version = Get-AppLockerFileInformation -Path $AddInInstaller.FullName | Select-Object -ExpandProperty "Publisher"
$AddInPath = "${Env:ProgramFiles(x86)}\Microsoft\TeamsMeetingAddin\$($Version.BinaryVersion.ToString())"

$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($AddInInstaller.FullName)`" ALLUSERS=1 TARGETDIR=`"$AddInPath`" /quiet /norestart"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Continue"
}
$result = Start-Process @params
Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
#endregion
