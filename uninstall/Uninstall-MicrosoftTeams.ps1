#description: Uninstalls Microsoft Teams
#execution mode: Combined
#tags: Uninstall, Microsoft, Teams

#region Functions
function Get-InstalledSoftware {
    [OutputType([System.Object[]])]
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
            throw $_
        }
    }
    return $Apps
}
#endregion

#region Script logic
New-Item -Path "$env:ProgramData\NerdioManager\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    $Apps = Get-InstalledSoftware | Where-Object { $_.Name -match "Teams Machine-Wide Installer*" }
    foreach ($App in $Apps) {
        $params = @{
            FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
            ArgumentList = "/uninstall `"$($App.PSChildName)`" /quiet /norestart /log `"$env:ProgramData\NerdioManager\Logs\UninstallMicrosoftTeams$($App.Version).log`""
            NoNewWindow  = $True
            PassThru     = $True
            Wait         = $True
        }
        $result = Start-Process @params
    }
}
catch {
    throw $_
}
finally {
    exit $result.ExitCode
}
#endregion
