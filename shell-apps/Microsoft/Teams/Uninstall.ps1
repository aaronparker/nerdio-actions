# Variables
[System.String] $PackageFamilyName = "MSTeams_8wekyb3d8bbwe"

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

Get-InstalledSoftware | Where-Object { $_.Name -match "Microsoft Teams Meeting Add-in*" } | ForEach-Object {
    $Context.Log("Uninstalling Windows Installer: $($_.PSChildName)")
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/uninstall `"$($_.PSChildName)`" /quiet /norestart"
        Wait         = $true
        PassThru     = $true
        NoNewWindow  = $true
        ErrorAction  = "Stop"
    }
    $result = Start-Process @params
    $Context.Log("Uninstall complete. Return code: $($result.ExitCode)")
}

Get-AppxPackage -AllUsers | Where-Object { $_.PackageFamilyName -eq $PackageFamilyName } | ForEach-Object {
    $Context.Log("Removing existing AppX package: $($_.Name)")
    $_ | Remove-AppxPackage -AllUsers -ErrorAction "Stop"
}
Start-Sleep -Seconds 10
$Context.Log("Uninstall complete")
