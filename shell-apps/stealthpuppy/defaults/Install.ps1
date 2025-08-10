$Context.Log("Installing Windows Enterprise Defaults")
Get-ChildItem -Path $PWD -Include "Install-Defaults.ps1" -Recurse -File | ForEach-Object {
    $Context.Log("Executing: $($_.FullName)")
    & $_.FullName
}
$Context.Log("Install complete")
