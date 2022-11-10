#description: Installs the supported Microsoft Visual C++ Redistributables
#execution mode: Combined
#tags: VcRedist
#Requires -Modules VcRedist
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\VcRedist"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

# Run tasks/install apps
try {
    Import-Module -Name "VcRedist" -Force
    Save-VcRedist -VcList (Get-VcList) -Path $Path > $Null
    Install-VcRedist -VcList (Get-VcList) -Path $Path -Silent | Out-Null
}
catch {
    throw $_.Exception.Message
}
#endregion
