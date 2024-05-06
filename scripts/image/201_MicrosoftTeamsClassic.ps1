<#
.SYNOPSIS
Installs the latest Microsoft Teams per-machine for use on Windows 10/11 multi-session or Windows Server.

.DESCRIPTION
This script installs the latest version of Microsoft Teams per-machine.
It first checks if the Teams application is already installed and, if so, uninstalls it.
Then it downloads the latest version of Teams using the Evergreen module and installs it.
Finally, it optimizes Teams for multi-session without GPU support by deleting the registry auto-start and updating the default profile.

.PARAMETER Path
The download path for Microsoft Teams.
#>

#description: Installs the latest Microsoft Teams per-machine for use on Windows 10/11 multi-session or Windows Server
#execution mode: Combined
#tags: Evergreen, Microsoft, Teams, per-machine
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Teams"
[System.String] $TeamsExe = "${env:ProgramFiles(x86)}\Microsoft\Teams\current\Teams.exe"

#region Functions
function Get-InstalledSoftware {
    [OutputType([System.Object[]])]
    [CmdletBinding()]
    param ()
    $UninstallKeys = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
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
            throw $_
        }
    }
    return $Apps
}
#endregion

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    [System.String] $Language = "en-AU"
}
else {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $params = @{
        Uri             = $SecureVars.VariablesList
        UseBasicParsing = $true
        ErrorAction     = "Stop"
    }
    $Variables = Invoke-RestMethod @params
    [System.String] $Language = $Variables.$AzureRegionName.Language
}
#endregion

# Download Teams
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "MicrosoftTeamsClassic" | `
    Where-Object { $_.Architecture -eq "x64" -and $_.Ring -eq "General" -and $_.Type -eq "msi" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

# Uninstall the existing Teams
if (Test-Path -Path $TeamsExe) {
    $File = Get-ChildItem -Path $TeamsExe
    if ([System.Version]$File.VersionInfo.ProductVersion -le [System.Version]$App.Version) {
        $LogFile = "$Env:ProgramData\Nerdio\Logs\UninstallMicrosoftTeams$($File.VersionInfo.ProductVersion).log" -replace " ", ""
        $params = @{
            FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
            ArgumentList = "/x `"$($OutFile.FullName)`" /quiet /log $LogFile"
            NoNewWindow  = $true
            Wait         = $true
            PassThru     = $true
            ErrorAction  = "Continue"
        }
        Start-Process @params

        $Folders = "${env:ProgramFiles(x86)}\Microsoft\Teams", `
            "${env:ProgramFiles(x86)}\Microsoft\TeamsMeetingAddin", `
            "${env:ProgramFiles(x86)}\Microsoft\TeamsPresenceAddin"
        Remove-Item -Path $Folders -Recurse -Force -ErrorAction "Ignore"
    }
}

$Apps = Get-InstalledSoftware | Where-Object { $_.Name -match "Teams Machine-Wide Installer" }
foreach ($App in $Apps) {
    $LogFile = "$Env:ProgramData\Nerdio\Logs\UninstallMicrosoftTeamsMachineWideInstaller$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/uninstall `"$($App.PSChildName)`" /quiet /norestart /log $LogFile"
        NoNewWindow  = $true
        PassThru     = $true
        Wait         = $true
        ErrorAction  = "Continue"
    }
    Start-Process @params
}

# Install Teams
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Name "IsWVDEnvironment" -PropertyType "DWORD" -Value 1 -Force -ErrorAction "SilentlyContinue" | Out-Null
$LogFile = $LogFile = "$Env:ProgramData\Nerdio\Logs\MicrosoftTeams$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package $($OutFile.FullName) OPTIONS=`"noAutoStart=true`" ALLUSER=1 ALLUSERS=1 /quiet /log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Continue"
}
Start-Process @params
#endregion

#region Optimise Teams for multi-session without GPU support
# Delete the registry auto-start
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "Teams" /f | Out-Null

# Disable GPU acceleration by default by updating the default profile
$DesktopSetupJson = @"
{
    "appPreferenceSettings": {
        "runningOnClose": true,
        "disableGpu": true,
        "callingMWEnabledPreferenceKey": false
    },
    "theme": "default",
    "currentWebLanguage": "$Language"
}
"@
New-Item -Path "$Env:SystemDrive\Users\Default\AppData\Roaming\Microsoft\Teams" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
$FilePath = "$Env:SystemDrive\Users\Default\AppData\Roaming\Microsoft\Teams\desktop-config.json"
$Utf8NoBomEncoding = New-Object -TypeName "System.Text.UTF8Encoding" -ArgumentList $false
[System.IO.File]::WriteAllLines($FilePath, $DesktopSetupJson, $Utf8NoBomEncoding)
#endregion
