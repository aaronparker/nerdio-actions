# Variables
[System.String] $FilePath = "${Env:ProgramFiles}\FSLogix\Apps\frxsvc.exe"

# Detection logic
if (Test-Path -Path $FilePath) {
    $FileItem = Get-ChildItem -Path $FilePath -ErrorAction "SilentlyContinue"
    $Context.Log("File found: $($FileItem.FullName)")

    # FSLogix version will be in the form of "25.06", so we need construct the version numbers to compare
    $FileInfo = [Diagnostics.FileVersionInfo]::GetVersionInfo($FileItem.FullName)
    $ProductVersion = [System.Version]::Parse("$($FileInfo.ProductVersion).0")
    $ContextVersion = [System.Version]::Parse("$($Context.TargetVersion).0")
    $CompareContextVersion = [System.Version]::Parse("3.$($ContextVersion.Major).0")
    
    if ($ProductVersion -ge $CompareContextVersion) {
        $Context.Log("No update required. Found '$($ProductVersion.ToString())' against '$($CompareContextVersion.ToString())'.")
        if ($Context.Versions -is [System.Array]) { return $Context.TargetVersion } else { return $true }
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
