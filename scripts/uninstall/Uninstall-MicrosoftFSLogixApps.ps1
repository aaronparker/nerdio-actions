#description: Uninstalls the Microsoft FSLogix Apps agent
#execution mode: IndividualWithRestart
#tags: Uninstall, Microsoft, FSLogix

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
New-Item -Path "$Env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    # Stop services
    Stop-Service -Name "frxsvc", "frxccds" -Force -ErrorAction "Ignore"
}
catch {
    Write-Warning -Message "Failed to stop services with error: $($_.Exception.Message)"
}

try {
    Get-Process -ErrorAction "SilentlyContinue" | `
        Where-Object { $_.Path -like "$Env:ProgramFiles\FSLogix\Apps\*" } | `
        Stop-Process -Force -ErrorAction "SilentlyContinue"
}
catch {
    Write-Warning -Message "Failed to stop processes."
}

$Apps = Get-InstalledSoftware | Where-Object { $_.Name -match "Microsoft FSLogix Apps*" }
foreach ($App in $Apps) {
    $LogFile = "$Env:ProgramData\Evergreen\Logs\UninstallMicrosoftFSLogixApps$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = [Regex]::Match($App.UninstallString, '\"(.*)\"').Captures.Groups[1].Value
        ArgumentList = "/uninstall /quiet /norestart /log $LogFile"
        NoNewWindow  = $True
        PassThru     = $True
        Wait         = $True
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    $result.ExitCode
}
if ($result.ExitCode -eq 0) {
    if (Test-Path -Path "$Env:ProgramFiles\FSLogix") {
        Remove-Item -Path "$Env:ProgramFiles\FSLogix" -Recurse -Force -ErrorAction "Ignore"
    }
}
