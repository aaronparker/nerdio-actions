# Variables
[System.String] $FilePath = "${Env:SystemRoot}\SysWOW64\vcruntime140.dll"
[System.String] $DisplayName = "Microsoft Visual C\+\+ 2015-2022 Redistributable (x86)*"

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

# Get the installed appplication
$App = Get-InstalledSoftware | Where-Object { $_.Name -match $DisplayName }

# Detection logic
if ([System.String]::IsNullOrEmpty($Context.TargetVersion)) {
    # This should be an uninstall action
    if ($App) { return $true }
    else {
        if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
    }
}
else {
    # This should be an install action, so we need to check the file version
    if ($App) {
        $Context.Log("Found version: $($App.Version)")
        $Context.Log("Target Shell App version: $($Context.TargetVersion)")
        if ([System.Version]::Parse($App.Version) -ge [System.Version]::Parse($Context.TargetVersion)) {
            $Context.Log("No update required. Found '$($App.Version)' against '$($Context.TargetVersion)'.")
            if ($Context.Versions -is [System.Array]) { return $App.Version } else { return $true }
        }
        else {
            $Context.Log("Update required. Found '$($App.Version)' less than '$($Context.TargetVersion)'.")
            if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
        }
    }
    else {
        $Context.Log("File does not exist at: $($FilePath)")
        if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
    }
}
