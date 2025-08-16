# Variables
[System.String] $FilePath = "${Env:ProgramFiles}\PowerShell\7\pwsh.exe"

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
        $Context.Log("File product version: $($FileInfo.FileVersion)")
        $Context.Log("Target Shell App version: $($Context.TargetVersion)")
        if ([System.Version]::Parse($FileInfo.FileVersion) -ge [System.Version]::Parse($Context.TargetVersion)) {
            $Context.Log("No update required. Found '$($FileInfo.FileVersion)' against '$($Context.TargetVersion)'.")
            if ($Context.Versions -is [System.Array]) { return $FileInfo.FileVersion } else { return $true }
        }
        else {
            $Context.Log("Update required. Found '$($FileInfo.FileVersion)' less than '$($Context.TargetVersion)'.")
            if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
        }
    }
    else {
        $Context.Log("File does not exist at: $($FilePath)")
        if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
    }
}
