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
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

#region Script logic
# Download and unpack
Import-Module -Name "Evergreen" -Force

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
# Use Evergreen to find the latest version
$App = Get-EvergreenApp -Name "MicrosoftFSLogixApps" | Where-Object { $_.Channel -eq "Production" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
Write-LogFile -Message "Downloaded Microsoft FSLogix Apps agent to: $($OutFile.FullName)"
Write-LogFile -Message "Expand file to: $Path"
Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force

# Install
$LogPath = (Get-LogFile).Path
foreach ($File in "FSLogixAppsSetup.exe") {
    $Installers = Get-ChildItem -Path $Path -Recurse -Include $File | Where-Object { $_.Directory -match "x64" }
    foreach ($Installer in $Installers) {
        $LogFile = "$LogPath\$($Installer.Name)$($App.Version).log" -replace " ", ""
        Write-LogFile -Message "Installing Microsoft FSLogix Apps agent"
        $params = @{
            FilePath     = $Installer.FullName
            ArgumentList = "/install /quiet /norestart /log $LogFile"
        }
        Start-ProcessWithLog @params
    }
}

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:ProgramData\Microsoft\Windows\Start Menu\FSLogix\FSLogix Apps Online Help.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
