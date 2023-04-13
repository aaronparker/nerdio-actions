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
#endregion

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    # Download Teams
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "MicrosoftTeams" | `
        Where-Object { $_.Architecture -eq "x64" -and $_.Ring -eq "General" -and $_.Type -eq "msi" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}

try {
    # Uninstall the existing Teams
    if (Test-Path -Path $TeamsExe) {
        $File = Get-ChildItem -Path $TeamsExe
        if ([System.Version]$File.VersionInfo.ProductVersion -le [System.Version]$App.Version) {
            Write-Information -MessageData ":: Uninstall Microsoft Teams" -InformationAction "Continue"
            $LogFile = "$Env:ProgramData\Evergreen\Logs\UninstallMicrosoftTeams$($File.VersionInfo.ProductVersion).log" -replace " ", ""
            $params = @{
                FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
                ArgumentList = "/x `"$($OutFile.FullName)`" /quiet /log $LogFile"
                NoNewWindow  = $true
                Wait         = $true
                PassThru     = $true
                ErrorAction  = "Continue"
            }
            $result = Start-Process @params
            $result.ExitCode

            $Folders = "${env:ProgramFiles(x86)}\Microsoft\Teams", `
                "${env:ProgramFiles(x86)}\Microsoft\TeamsMeetingAddin", `
                "${env:ProgramFiles(x86)}\Microsoft\TeamsPresenceAddin"
            Remove-Item -Path $Folders -Recurse -Force -ErrorAction "Ignore"
        }
    }
}
catch {
    throw $_.Exception.Message
}

$Apps = Get-InstalledSoftware | Where-Object { $_.Name -match "Teams Machine-Wide Installer" }
foreach ($App in $Apps) {
    try {
        Write-Information -MessageData ":: Uninstall Microsoft Teams Machine Wide Installer" -InformationAction "Continue"
        $LogFile = "$Env:ProgramData\Evergreen\Logs\UninstallMicrosoftTeamsMachineWideInstaller$($App.Version).log" -replace " ", ""
        $params = @{
            FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
            ArgumentList = "/uninstall `"$($App.PSChildName)`" /quiet /norestart /log $LogFile"
            NoNewWindow  = $True
            PassThru     = $True
            Wait         = $True
            ErrorAction  = "Continue"
        }
        $result = Start-Process @params
        $result.ExitCode
    }
    catch {
        throw $_.Exception.Message
    }
}

try {
    # Install Teams
    Write-Information -MessageData ":: Install Microsoft Teams" -InformationAction "Continue"
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Force -ErrorAction "SilentlyContinue" | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Name "IsWVDEnvironment" -PropertyType "DWORD" -Value 1 -Force -ErrorAction "SilentlyContinue" | Out-Null
    $LogFile = $LogFile = "$Env:ProgramData\Evergreen\Logs\MicrosoftTeams$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package $($OutFile.FullName) OPTIONS=`"noAutoStart=true`" ALLUSER=1 ALLUSERS=1 /quiet /log $LogFile"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
}
catch {
    throw $_.Exception.Message
}

try {
    # Teams JSON files; Read the file and convert from JSON
    $ConfigFiles = @((Join-Path -Path "${env:ProgramFiles(x86)}\Teams Installer" -ChildPath "setup.json"), (Join-Path -Path "${env:ProgramFiles(x86)}\Microsoft\Teams" -ChildPath "setup.json"))
    foreach ($Path in $ConfigFiles) {
        if (Test-Path -Path $Path) {
            $Json = Get-Content -Path $Path | ConvertFrom-Json
            $Json.noAutoStart = $true
            $Json | ConvertTo-Json | Set-Content -Path $Path -Force
        }
    }
}
catch {
    throw $_.Exception.Message
}

# Delete the registry auto-start
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "Teams" /f | Out-Null
#endregion
