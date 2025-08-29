<#
    Remove or disable Windows 365 agents and components
#>
[CmdletBinding(SupportsShouldProcess = $false)]
param (
    [Parameter(Mandatory = $false)]
    [System.String] $Path = "$Env:SystemRoot\Temp"
)

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$InformationPreference = [System.Management.Automation.ActionPreference]::Continue
$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

function Get-InstalledSoftware {
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
                Sort-Object -Property "Name", "Publisher"
        }
        catch {
            throw $_.Exception.Message
        }
    }

    Remove-PSDrive -Name "HKU" -ErrorAction "SilentlyContinue" | Out-Null
    return $Apps
}

# Query API for Azure VM information
$params = @{
    Headers = @{"Metadata" = "true" }
    Method  = "GET"
    Uri     = "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
}
$result = Invoke-RestMethod @params
if ($result.compute.tagsList.name -match "ms.inv*") {
    # Windows 365
    Write-Information -MessageData "Running in Windows 365"
    Get-Service -Name "CloudManagedDesktopExtension" -ErrorAction "SilentlyContinue" | ForEach-Object {
        if ($_.Status -ne "Running") {
            Write-Information -MessageData "Starting: $($_.Name)"
            Start-Service -Name $_.Name
            Set-Service -Name $_.Name -StartupType "Automatic"
        }
    }
    return 0
}
else {
    # Azure Virtual Desktop
    Write-Information -MessageData "Running in Azure Virtual Desktop"
    Write-Information -MessageData "Export HKLM\SOFTWARE\Microsoft\Windows365 to: $Path\Windows365.reg"
    reg export "HKLM\SOFTWARE\Microsoft\Windows365" $Path\Windows365.reg | Out-Null
    Write-Information -MessageData "Delete: HKLM\SOFTWARE\Microsoft\Windows365"
    reg delete "HKLM\SOFTWARE\Microsoft\Windows365" /f | Out-Null

    Write-Information -MessageData "Unregistering Scheduled Task: SetDeviceModel"
    Get-ScheduledTask -TaskName "SetDeviceModel" | Unregister-ScheduledTask
    $params = @{
        Path         = "HKLM:\SYSTEM\ControlSet001\Control\SystemInformation"
        Name         = "SystemProductName"
        Value        = "Virtual Machine"
        PropertyType = "String"
        Force        = $true
    }
    New-ItemProperty @params

    Get-Service -Name "CloudManagedDesktopExtension" -ErrorAction "SilentlyContinue" | ForEach-Object {
        Write-Information -MessageData "Stopping: $($_.Name)"
        Stop-Service -Name $_.Name
        Set-Service -Name $_.Name -StartupType "Disabled"
    }
    Get-InstalledSoftware | Where-Object { $_.Name -match "Microsoft Cloud Managed Desktop Extension|Microsoft Device Inventory Agent" } | ForEach-Object {
        Write-Information -MessageData "Uninstalling: $($_.Name)"
        $ArgumentList = "/uninstall `"$($_.PSChildName)`" /quiet /norestart /log `"$Path\$($_.PSChildName).log`""
        $params = @{
            FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
            ArgumentList = $ArgumentList
            NoNewWindow  = $true
            PassThru     = $false
            Wait         = $true
        }
        Start-Process @params
    }
}
