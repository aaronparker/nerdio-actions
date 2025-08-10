# Variables
[System.String] $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{f38de27b-799e-4c30-8a01-bfdedc622944}"
[System.String] $Value = "DisplayVersion"

# Detection logic
if (Test-Path -Path $RegPath) {
    $Context.Log("Key found: $RegPath")
    $RegItem = Get-ItemProperty -Path $RegPath -ErrorAction "SilentlyContinue"
    if ([System.Version]::Parse($RegItem.$Value) -ge [System.Version]::Parse($Context.TargetVersion)) {
        $Context.Log("No update required. Found '$($RegItem.$Value)' against '$($Context.TargetVersion)'.")
        if ($Context.Versions -is [System.Array]) { return $RegItem.$Value } else { return $true }
    }
    else {
        $Context.Log("Update required. Found '$($RegItem.$Value)' less than '$($Context.TargetVersion)'.")
        if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
    }
}
else {
    $Context.Log("Path does not exist at: $($RegPath)")
    if ($Context.Versions -is [System.Array]) { return $null } else { return $false }
}
