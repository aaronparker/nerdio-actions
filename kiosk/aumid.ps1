
Get-AppxPackage | Where-Object { $_.Name -like "*SlimCore*" } | ForEach-Object {
    $Package = $_
    foreach ($id in (Get-AppxPackageManifest $Package).Package.Applications.Application.Id) {
        "<App AppUserModelId=`"$($Package.PackageFamilyName)!$($id)`" />"
    }
} | Set-Clipboard
