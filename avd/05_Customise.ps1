#description: Installs Windows Customised Defaults
#execution mode: Combined
#tags: Evergreen, Default profile, Customisation
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\image-customise"

# Use variables in Nerdio Manager to pass a system language
if ($null -eq $SecureVars.OSLanguage) {
    [System.String] $Language = "en-AU"
}
else {
    [System.String] $Language = $SecureVars.OSLanguage
}

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null
try {
    $Installer = Get-EvergreenApp -Name "stealthpuppyWindowsCustomisedDefaults" | Where-Object { $_.Type -eq "zip" } | `
        Select-Object -First 1 | `
        Save-EvergreenApp -CustomPath $Path
    Expand-Archive -Path $Installer.FullName -DestinationPath $Path -Force
    Push-Location -Path $Path
    .\Install-Defaults.ps1 -Language $Language
}
catch {
    throw "$($Script.FullName) error with: $($_.Exception.Message)."
}
finally {
    Pop-Location
}
#endregion
