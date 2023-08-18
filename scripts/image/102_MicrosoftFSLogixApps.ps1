#description: Installs the latest Microsoft FSLogix Apps agent and the FSLogix Apps Rules Editor
#execution mode: Combined
#tags: Evergreen, Microsoft, FSLogix
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\FSLogix"

#region Agent history - allow installing a specific version in the event of an issue
$Versions = @"
[
    {
        "Version": "2.9.8440.42104",
        "Date": "03/04/2022",
        "Channel": "Production",
        "URI": "https://download.microsoft.com/download/c/4/4/c44313c5-f04a-4034-8a22-967481b23975/FSLogix_Apps_2.9.8440.42104.zip"
    },
    {
        "Version": "2.9.8361.52326",
        "Date": "12/13/2022",
        "Channel": "Production",
        "URI": "https://download.microsoft.com/download/0/a/4/0a4c3a18-f6c8-4bcd-91fc-97ce845e2d3e/FSLogix_Apps_2.9.8361.52326.zip"
    },
    {
        "Version": "2.9.8228.50276",
        "Date": "07/21/2022",
        "Channel": "Production",
        "URI": "https://download.microsoft.com/download/d/1/9/d190de51-f1c1-4581-9007-24e5a812d6e9/FSLogix_Apps_2.9.8228.50276.zip"
    },
    {
        "Version": "2.9.8171.14983",
        "Date": "05/24/2022",
        "Channel": "Production",
        "URI": "https://download.microsoft.com/download/e/a/1/ea1bcf0a-e66d-48d2-ac9f-e385e5a7456e/FSLogix_Apps_2.9.8171.14983.zip"
    },
    {
        "Version": "2.9.8111.53415",
        "Date": "03/25/2022",
        "Channel": "Production",
        "URI": "https://download.microsoft.com/download/9/2/5/9257adcf-abdf-4ab3-b37f-416d70682315/FSLogix_Apps_2.9.8111.53415.zip"
    }
]
"@
#endregion


#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    # Download and unpack
    Import-Module -Name "Evergreen" -Force

    # Use Secure variables in Nerdio Manager to pass variables
    if ($null -eq $SecureVars.FSLogixAgentVersion) {
        # Use Evergreen to find the latest version
        $App = Get-EvergreenApp -Name "MicrosoftFSLogixApps" | Where-Object { $_.Channel -eq "Production" } | Select-Object -First 1
    }
    else {
        # Use the JSON in this script to select a specific version
        $App = $Versions | ConvertFrom-Json | Where-Object { $_.Version -eq $SecureVars.FSLogixAgentVersion }
    }

    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
    Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force
}
catch {
    Write-Information -MessageData $_.Exception.Message -InformationAction "Continue"
}

# Install
Write-Information -MessageData ":: Install Microsoft FSLogix agent" -InformationAction "Continue"
foreach ($file in "FSLogixAppsSetup.exe", "FSLogixAppsRuleEditorSetup.exe") {
    $Installers = Get-ChildItem -Path $Path -Recurse -Include $file | Where-Object { $_.Directory -match "x64" }
    foreach ($Installer in $Installers) {
        try {
            $LogFile = "$Env:ProgramData\Nerdio\Logs\$($Installer.Name)$($App.Version).log" -replace " ", ""
            $params = @{
                FilePath     = $Installer.FullName
                ArgumentList = "/install /quiet /norestart /log $LogFile"
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
    }
}

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:ProgramData\Microsoft\Windows\Start Menu\FSLogix\FSLogix Apps Online Help.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
