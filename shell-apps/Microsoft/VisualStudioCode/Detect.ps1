# Variables
[System.String] $FilePath = "${Env:ProgramFiles}\Microsoft VS Code\Code.exe"
[System.String] $Version = "1.99.3"

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
