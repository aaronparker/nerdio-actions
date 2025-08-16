# Variables
[System.String] $FilePath = "${Env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
[System.String] $PrefsPath = "${Env:ProgramFiles(x86)}\Microsoft\Edge\Application\initial_preferences"

# Detection logic
if ([System.String]::IsNullOrEmpty($Context.TargetVersion)) {
    # This should be an uninstall action
    if (Test-Path -Path $FilePath) { return $true }
    else {
        if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
    }
}
else {
    if (Test-Path -Path $FilePath) {
        if (Test-Path -Path $PrefsPath) {
            $FileItem = Get-ChildItem -Path $FilePath -ErrorAction "SilentlyContinue"
            $Context.Log("File found: $($FileItem.FullName)")
            $FileInfo = [Diagnostics.FileVersionInfo]::GetVersionInfo($FileItem.FullName)
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
            $Context.Log("File does not exist at: $($PrefsPath)")
            if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
        }
    }
    else {
        $Context.Log("File does not exist at: $($FilePath)")
        if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
    }
}
