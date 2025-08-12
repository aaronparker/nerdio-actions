# Variables
[System.String] $FilePath = "${Env:ProgramFiles}\FSLogix\Apps\frxsvc.exe"

# Detection logic
if (Test-Path -Path $FilePath) {
    $FileItem = Get-ChildItem -Path $FilePath -ErrorAction "SilentlyContinue"
    $Context.Log("File found: $($FileItem.FullName)")
    $ProductVersion = [System.Version]::Parse($FileInfo.ProductVersion)
    $ContextVersion = [System.Version]::Parse($Context.TargetVersion)
    if ([System.Version]::Parse("$($ProductVersion.Major).$($ProductVersion.Minor)") -ge [System.Version]::Parse("3.$($ContextVersion.Major)")) {
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
