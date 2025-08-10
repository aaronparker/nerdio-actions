$Context.Log("Uninstalling Windows Enterprise Defaults")
Get-ChildItem -Path $PWD -Include "Remove-Defaults.ps1" -Recurse -File | ForEach-Object {
    $Context.Log("Executing: $($_.FullName)")
    & $_.FullName
}
$Context.Log("Uninstall complete")
