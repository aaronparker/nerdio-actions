# Variables
[System.String] $FilePath = "${Env:ProgramFiles}\ImageGlass\ImageGlass.exe"

# Detection logic
if (Test-Path -Path $FilePath) {
    $FileItem = Get-ChildItem -Path $FilePath -ErrorAction "SilentlyContinue"
    $Context.Log("File found: $($FileItem.FullName)")
    $FileInfo = [Diagnostics.FileVersionInfo]::GetVersionInfo($FileItem.FullName)
    $Context.Log("Found version: $($FileInfo.FileVersion)")
    $Context.Log("Compare to: $($Context.TargetVersion)")
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
