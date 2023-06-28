#description: Uninstalls Microsoft OneDrive
#execution mode: Combined
#tags: Uninstall, Microsoft, OneDrive

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
New-Item -Path "$Env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Get-Process -ErrorAction "SilentlyContinue" | `
        Where-Object { $_.Path -like "$Env:ProgramFiles\Microsoft OneDrive\*" } | `
        Stop-Process -Force -ErrorAction "SilentlyContinue"
}
catch {
    Write-Warning -Message "Failed to stop processes."
}

$Apps = Get-InstalledSoftware | Where-Object { $_.Name -match "Microsoft OneDrive*" }
foreach ($App in $Apps) {
    $params = @{
        FilePath     = [Regex]::Match($App.UninstallString, '^(.*.exe)\s').Captures.Groups[1].Value
        ArgumentList = "/uninstall /allusers /quiet /norestart"
        NoNewWindow  = $true
        PassThru     = $true
        Wait         = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    $result.ExitCode
}
if ($result.ExitCode -eq 0) {
    if (Test-Path -Path "$Env:ProgramFiles\Microsoft OneDrive") {
        Remove-Item -Path "$Env:ProgramFiles\Microsoft OneDrive" -Recurse -Force -ErrorAction "Ignore"
    }
}
