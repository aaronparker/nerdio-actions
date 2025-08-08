# Variables
[System.String] $FilePath = "${Env:ProgramFiles}\dotnet\host\fxr\$($Context.TargetVersion)\hostfxr.dll"

# Detection logic
if (Test-Path -Path $FilePath) {
    # Version on the file won't match the version of the .NET runtime, so we need to check the file's existence only.
    $Context.Log("File exists at: $($FilePath)")
    return $true
}
else {
    $Context.Log("File does not exist at: $($FilePath)")
    if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
}
