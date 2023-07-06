#description: Uninstalls the Microsoft .NET Windows Desktop Runtime
#execution mode: Combined
#tags: Uninstall, Microsoft, .NET

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
            throw $_.Exception.Message
        }
    }
    return $Apps
}
#endregion

#region Script logic
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

$Apps = Get-InstalledSoftware | Where-Object { $_.Name -match "Microsoft Windows Desktop Runtime*" }
foreach ($App in $Apps) {
    $LogFile = "$Env:ProgramData\Nerdio\Logs\UninstallMicrosoft.NET$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = [Regex]::Match($App.UninstallString, '\"(.*)\"').Captures.Groups[1].Value
        ArgumentList = "/uninstall /quiet /norestart /log $LogFile"
        NoNewWindow  = $true
        PassThru     = $true
        Wait         = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    $result.ExitCode
}
#endregion
