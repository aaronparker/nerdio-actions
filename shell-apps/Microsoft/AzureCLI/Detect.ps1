[System.String] $DisplayName = "Microsoft Azure CLI"

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
                Sort-Object -Property "DisplayName", "Publisher"
        }
        catch {
            throw $_.Exception.Message
        }
    }
    return $Apps
}

$App = Get-InstalledSoftware | Where-Object { $_.Name -match "$DisplayName*" }
if ($App) {
    if ($Context.Versions -is [System.Array]) { return $_.Version } else { return $true }
}
else {
    $Context.Log("Application not installed: $DisplayName")
    if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
}
