# Variables
[System.String] $FilePath = "${Env:ProgramFiles}\Zoom\bin\Zoom.exe"

# Detection logic
if (Test-Path -Path $FilePath) {
    $FileItem = Get-ChildItem -Path $FilePath -ErrorAction "SilentlyContinue"
    $Context.Log("File found: $($FileItem.FullName)")
    $FileInfo = [Diagnostics.FileVersionInfo]::GetVersionInfo($FileItem.FullName)
    if ([System.Version]::Parse($FileInfo.ProductVersion) -ge [System.Version]::Parse($Context.TargetVersion)) {
        $Context.Log("No update required. Found '$($FileInfo.ProductVersion)' against '$($Context.TargetVersion)'.")
        return $true
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
