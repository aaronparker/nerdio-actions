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
#execution mode: Combined
#tags: Evergreen, Citrix
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Citrix\Workspace"

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    [System.String] $Stream = "Current"
}
else {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $params = @{
        Uri             = $SecureVars.VariablesList
        UseBasicParsing = $true
        ErrorAction     = "Stop"
    }
    $Variables = Invoke-RestMethod @params
    [System.String] $Stream = $Variables.$AzureRegionName.CitrixWorkspaceStream
}
#endregion

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "CitrixWorkspaceApp" | `
    Where-Object { $_.Stream -eq $Stream } | `
    Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path

Write-Information -MessageData ":: Install Citrix Workspace app" -InformationAction "Continue"
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/silent /noreboot /includeSSON /AutoUpdateCheck=Disabled EnableTracing=false EnableCEIP=False ADDLOCAL=ReceiverInside,ICA_Client,BCR_Client,DesktopViewer,AM,SSON,SELFSERVICE,WebHelper"
    NoNewWindow  = $true
    Wait         = $false
    PassThru     = $true
    ErrorAction  = "Continue"
}
$result = Start-Process @params
Start-Sleep -Seconds 120
Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"

# Disable update tasks - assuming we're installing on a gold image or updates will be managed
Get-Service -Name "CWAUpdaterService" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"

# Remove startup items
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "AnalyticsSrv" /f | Out-Null
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "ConnectionCenter" /f | Out-Null
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "Redirector" /f | Out-Null
#endregion
