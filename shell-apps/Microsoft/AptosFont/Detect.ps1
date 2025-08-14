# Variables
[System.String] $FilePath = "$Env:SystemRoot\Fonts\Aptos.ttf"

# Detection logic
if (Test-Path -Path $FilePath) {
    return $Context.TargetVersion
}
else {
    $Context.Log("File does not exist at: $($FilePath)")
    if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
}
