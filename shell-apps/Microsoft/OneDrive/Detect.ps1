# Variables
[System.String] $FilePath = "${Env:ProgramFiles}\Microsoft OneDrive\OneDrive.exe"
[System.String] $DisplayName = "Microsoft OneDrive"

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

# Detection logic
if ([System.String]::IsNullOrEmpty($Context.TargetVersion)) {
    # This should be an uninstall action
    if (Test-Path -Path $FilePath) { return $true }
    else {
        if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
    }
}
else {
    # This should be an install action, so we need to check the file version
    if (Test-Path -Path $FilePath) {
        $Context.Log("File found: $FilePath")
        $FileItem = Get-ChildItem -Path $FilePath -ErrorAction "SilentlyContinue"
        $FileInfo = [Diagnostics.FileVersionInfo]::GetVersionInfo($FileItem.FullName)
        $Context.Log("File product version: $($FileInfo.ProductVersion)")
        $Context.Log("Target Shell App version: $($Context.TargetVersion)")
        if ([System.Version]::Parse($FileInfo.ProductVersion) -ge [System.Version]::Parse($Context.TargetVersion)) {
            $Context.Log("No update required. Found '$($FileInfo.ProductVersion)' against '$($Context.TargetVersion)'.")
            if ($Context.Versions -is [System.Array]) { return $FileInfo.ProductVersion } else { return $true }
        }
        else {
            $Context.Log("Update required. Found '$($FileInfo.ProductVersion)' less than '$($Context.TargetVersion)'.")
            if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
        }
    }
    else {
        $App = Get-InstalledSoftware | Where-Object { $_.Name -match "$DisplayName*" }
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
}
