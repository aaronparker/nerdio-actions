# Variables
[System.String] $PackageFamilyName = "MicrosoftCorporationII.Windows365_8wekyb3d8bbwe"

# Detection logic
$App = Get-AppxPackage -AllUsers | Where-Object { $_.PackageFamilyName -eq $PackageFamilyName }
if ($null -eq $App) {
    $Context.Log("Microsoft Windows App is not installed.")
    return $false
}
else {
    $Context.Log("Found version: $($App.Version)")
    if ([System.Version]::Parse($App.Version) -ge [System.Version]::Parse($Context.TargetVersion)) {
        $Context.Log("No update required. Found '$($App.Version)' against '$($Context.TargetVersion)'.")
        return $true
    }
    else {
        $Context.Log("Update required. Found '$($App.Version)' less than '$($Context.TargetVersion)'.")
        return $false
    }
}
