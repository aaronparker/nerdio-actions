#description: Installs the supported Microsoft Visual C++ Redistributables
#execution mode: Combined
#tags: VcRedist, Microsoft
#Requires -Modules VcRedist
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\VcRedist"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Run tasks/install apps
try {
    Import-Module -Name "VcRedist" -Force
    Save-VcRedist -VcList (Get-VcList) -Path $Path | Out-Null
}
catch {
    throw $_
}

try {
    Install-VcRedist -VcList (Get-VcList) -Path $Path -Silent | Out-Null
}
catch {
    throw $_.Exception.Message
}
#endregion
