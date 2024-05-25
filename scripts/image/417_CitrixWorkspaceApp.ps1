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

#region Functions
function Get-InstalledSoftware {
    [OutputType([System.Object[]])]
    [CmdletBinding()]
    param ()

    try {
        try {
            $params = @{
                PSProvider  = "Registry"
                Name        = "HKU"
                Root        = "HKEY_USERS"
                ErrorAction = "SilentlyContinue"
            }
            New-PSDrive @params | Out-Null
        }
        catch {
            throw $_.Exception.Message
        }

        $UninstallKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        $UninstallKeys += Get-ChildItem -Path "HKU:" | Where-Object { $_.Name -match "S-\d-\d+-(\d+-){1,14}\d+$" } | ForEach-Object {
            "HKU:\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        }

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
    catch {
        throw $_.Exception.Message
    }
    finally {
        Remove-PSDrive "HKU" -ErrorAction "SilentlyContinue" | Out-Null
    }
}
#endregion

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force

# Try current release and fall back to LTSR the download fails
try {
    $App = Get-EvergreenApp -Name "CitrixWorkspaceApp" | `
        Where-Object { $_.Stream -eq "Current" } | `
        Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path
}
catch {
    $App = Get-EvergreenApp -Name "CitrixWorkspaceApp" | `
        Where-Object { $_.Stream -eq "LTSR" } | `
        Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path
}

$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/silent /noreboot /includeSSON /AutoUpdateCheck=Disabled EnableTracing=false EnableCEIP=False ADDLOCAL=ReceiverInside,ICA_Client,BCR_Client,DesktopViewer,AM,SSON,SELFSERVICE,WebHelper"
    NoNewWindow  = $true
    Wait         = $false
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params

# Wait for the installation to complete because Citrix can't work out how to write an installer correctly
do {
    Start-Sleep -Seconds 15
} while (Get-InstalledSoftware | Where-Object { $_.Name -match "Citrix Workspace*" })
Start-Sleep -Seconds 15

# Disable update tasks - assuming we're installing on a gold image or updates will be managed
Get-Service -Name "CWAUpdaterService" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"

# Remove startup items
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "AnalyticsSrv" /f | Out-Null
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "ConnectionCenter" /f | Out-Null
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "Redirector" /f | Out-Null
#endregion
