# Variables
[System.String] $FilePath = "${Env:ProgramFiles}\Audacity\Audacity.exe"

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
        $FileVersion = [System.Version]::Parse(($FileInfo.ProductVersion -replace ",", "."))
        $FileVersionJoin = $FileVersion.Major, $FileVersion.Minor, $FileVersion.Build -join "."
        $Context.Log("Found version: $FileVersionJoin")
        $Context.Log("Compare to: $($Context.TargetVersion)")
        if ([System.Version]::Parse($FileVersionJoin) -ge [System.Version]::Parse($Context.TargetVersion)) {
            $Context.Log("No update required. Found '$($FileInfo.ProductVersion)' against '$($Context.TargetVersion)'.")
            if ($Context.Versions -is [System.Array]) { return $FileInfo.ProductVersion } else { return $true }
        }
        else {
            $Context.Log("Update required. Found '$($FileInfo.ProductVersion)' less than '$($Context.TargetVersion)'.")
            if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
        }
    }
    else {
        $Context.Log("File does not exist at: $($FilePath)")
        if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
    }
}