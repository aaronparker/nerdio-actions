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

Get-InstalledSoftware | Where-Object { $_.Name -match "Microsoft Visual C\+\+ 2015-2022 Redistributable (x64)*" } | ForEach-Object {
    if ($_.UninstallString -match '"([^"]+)"') {
        $Context.Log("Uninstall with: $($Matches[1])")
        $params = @{
            FilePath     = $Matches[1]
            ArgumentList = "/uninstall /quiet /norestart"
            Wait         = $true
            NoNewWindow  = $true
            ErrorAction  = "Stop"
        }
        Start-Process @params
        $Context.Log("Uninstall complete")
    }
    else {
        $Context.Log("Failed to parse UninstallString")
    }
}
