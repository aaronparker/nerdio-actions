<#
.SYNOPSIS
Installs the latest Microsoft FSLogix Apps agent and the FSLogix Apps Rules Editor.

.DESCRIPTION
This script installs the latest version of the Microsoft FSLogix Apps agent and the FSLogix Apps Rules Editor.
It supports installing a specific version in case of any issues. The script downloads the agent from the specified URI,
unpacks it, and then installs it silently. It also removes any existing shortcuts to FSLogix Apps Online Help.

.PARAMETER Path
The path where the Microsoft FSLogix Apps agent will be downloaded. The default path is "$Env:SystemDrive\Apps\Microsoft\FSLogix".

.EXAMPLE
.\102_MicrosoftFSLogixApps.ps1 -Path "C:\Program Files\FSLogix"

.NOTES
- This script requires the Evergreen module to be installed.
- The script uses secure variables in Nerdio Manager to pass a JSON file with the variables list.
- The script requires an internet connection to download the Microsoft FSLogix Apps agent.
#>

#description: Installs the latest Microsoft FSLogix Apps agent
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

# Download and unpack
Import-Module -Name "Evergreen" -Force

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
$params = @{
    Uri             = $SecureVars.VariablesList
    UseBasicParsing = $true
    ErrorAction     = "Stop"
}
$Variables = Invoke-RestMethod @params
if ($null -eq $Variables.$AzureRegionName.FSLogixAgentVersion) {
    # Use Evergreen to find the latest version
    $App = Get-EvergreenApp -Name "MicrosoftFSLogixApps" | Where-Object { $_.Channel -eq "Production" } | Select-Object -First 1
}
else {
    # Use the JSON in this script to select a specific version
    $App = $Versions | ConvertFrom-Json | Where-Object { $_.Version -eq $Variables.$AzureRegionName.FSLogixAgentVersion }
}

$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force

# Install
foreach ($file in "FSLogixAppsSetup.exe") {
    $Installers = Get-ChildItem -Path $Path -Recurse -Include $file | Where-Object { $_.Directory -match "x64" }
    foreach ($Installer in $Installers) {
        $LogFile = "$Env:ProgramData\Nerdio\Logs\$($Installer.Name)$($App.Version).log" -replace " ", ""
        $params = @{
            FilePath     = $Installer.FullName
            ArgumentList = "/install /quiet /norestart /log $LogFile"
            NoNewWindow  = $true
            Wait         = $true
            PassThru     = $true
            ErrorAction  = "Stop"
        }
        Start-Process @params
    }
}

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:ProgramData\Microsoft\Windows\Start Menu\FSLogix\FSLogix Apps Online Help.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
