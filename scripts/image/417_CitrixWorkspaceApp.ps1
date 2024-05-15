<#
.SYNOPSIS
Installs the latest version of the Citrix Workspace app.

.DESCRIPTION
This script installs the latest version of the Citrix Workspace app.
It uses the Evergreen module to retrieve the appropriate version based on the specified stream.
The installation is performed silently with specific command-line arguments.

.PARAMETER Path
The path where the Citrix Workspace app will be download. The default path is "$Env:SystemDrive\Apps\Citrix\Workspace".

.NOTES
- This script requires the Evergreen module to be installed.
- The script assumes that the Citrix Workspace app installation file is available in the specified stream.
- The script disables the Citrix Workspace app update tasks and removes certain startup items.
#>

#description: Installs the latest version of the Citrix Workspace app
#execution mode: Individual
#tags: Evergreen, Citrix
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Citrix\Workspace"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force

# Try current release and fall back to LTSR if the download fails
try {
    $App = Get-EvergreenApp -Name "CitrixWorkspaceApp" | `
        Where-Object { $_.Stream -eq "Current" } | `
        Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path
}
catch {
    $App = Get-EvergreenApp -Name "CitrixWorkspaceApp" | `
        Where-Object { $_.Stream -eq "LTSR"} | `
        Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path
}

$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/silent /noreboot /includeSSON /AutoUpdateCheck=Disabled EnableTracing=false EnableCEIP=False ADDLOCAL=ReceiverInside,ICA_Client,BCR_Client,DesktopViewer,AM,SSON,SELFSERVICE,WebHelper"
    NoNewWindow  = $true
    Wait         = $false
    PassThru     = $true
    ErrorAction  = "Continue"
}
Start-Process @params
Start-Sleep -Seconds 120

# Disable update tasks - assuming we're installing on a gold image or updates will be managed
Get-Service -Name "CWAUpdaterService" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"

# Remove startup items
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "AnalyticsSrv" /f | Out-Null
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "ConnectionCenter" /f | Out-Null
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "Redirector" /f | Out-Null
#endregion
