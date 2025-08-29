function Get-InstalledSoftware {
    $PropertyNames = "DisplayName", "DisplayVersion", "Publisher", "UninstallString", "PSPath", "WindowsInstaller",
    "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize", "SystemComponent"
    ("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*") | `
        ForEach-Object {
        Get-ItemProperty -Path $_ -Name $PropertyNames -ErrorAction "SilentlyContinue" | `
            . { process { if ($null -ne $_.DisplayName) { $_ } } } | `
            Where-Object { $_.SystemComponent -ne 1 } | `
            Select-Object -Property @{n = "Name"; e = { $_.DisplayName } }, @{n = "Version"; e = { $_.DisplayVersion } }, "Publisher",
        "UninstallString", @{n = "RegistryPath"; e = { $_.PSPath -replace "Microsoft.PowerShell.Core\\Registry::", "" } },
        "PSChildName", "WindowsInstaller", "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize" | `
            Sort-Object -Property "Name", "Publisher"
    }
}

Get-InstalledSoftware | Where-Object { $_.Name -match "PowerToys*" } | ForEach-Object {
    if ($_.UninstallString -match '"([^"]+)"') {
        $Context.Log("Uninstall with: $($Matches[1])")
        $params = @{
            FilePath     = $Matches[1]
            ArgumentList = "/uninstall /quiet /norestart"
            Wait         = $true
            PassThru     = $true
            NoNewWindow  = $true
            ErrorAction  = "Stop"
        }
        $result = Start-Process @params
        $Context.Log("Uninstall complete. Return code: $($result.ExitCode)")
    }
    else {
        $Context.Log("Failed to parse UninstallString")
    }
}
