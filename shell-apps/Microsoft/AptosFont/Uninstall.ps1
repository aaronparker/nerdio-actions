Get-ChildItem -Path "$Env:SystemRoot\Fonts\Aptos*" | ForEach-Object {
    $Context.Log("Removing font file: $($_.FullName)")
    Remove-Item -Path $_.FullName -Force -ErrorAction "SilentlyContinue"
}
