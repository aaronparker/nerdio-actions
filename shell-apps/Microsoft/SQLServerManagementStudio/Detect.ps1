# Variables
[System.String] $FilePath = "${Env:ProgramFiles(x86)}\Microsoft SQL Server Management Studio 20\Common7\IDE\Ssms.exe"
[System.String] $Version = "20.1.10.0"

# Detection logic
if (Test-Path -Path $FilePath) {
    $FileItem = Get-ChildItem -Path $FilePath -ErrorAction "SilentlyContinue"
    $Context.Log("File found: $($FileItem.FullName)")
    $FileInfo = [Diagnostics.FileVersionInfo]::GetVersionInfo($FileItem.FullName)
    if ([System.Version]::Parse($FileInfo.ProductVersion) -ge [System.Version]::Parse($Version)) {
        $Context.Log("No update required. Found '$($FileInfo.ProductVersion)' against '$($Version)'.")
        return $true
    }
    else {
        $Context.Log("Update required. Found '$($FileInfo.ProductVersion)' less than '$($Version)'.")
        return $false
    }
}
else {
    $Context.Log("File does not exist at: $($FilePath)")
    return $false
}
