#description: Installs the supported Microsoft Visual C++ Redistributables
#execution mode: Combined
#tags: VcRedist
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\VcRedist"

#region Script logic
# Run tasks/install apps
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

Save-VcRedist -VcList (Get-VcList) -Path $Path > $Null
Install-VcRedist -VcList (Get-VcList) -Path $Path -Silent | Out-Null
#endregion
