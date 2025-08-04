# Variables
[System.String] $PackageFamilyName = "MicrosoftCorporationII.Windows365_8wekyb3d8bbwe"

Get-AppxPackage -AllUsers | Where-Object { $_.PackageFamilyName -eq $PackageFamilyName } | ForEach-Object {
    $Context.Log("Removing existing AppX package: $($_.Name)")
    $_ | Remove-AppxPackage -AllUsers -ErrorAction "Stop"
}
$Context.Log("Uninstall complete")
