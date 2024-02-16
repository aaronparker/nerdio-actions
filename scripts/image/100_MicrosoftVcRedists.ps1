#description: Installs the supported Microsoft Visual C++ Redistributables (2012, 2013, 2022)
#execution mode: Combined
#tags: VcRedist, Microsoft
#Requires -Modules VcRedist
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\VcRedist"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Run tasks/install apps
Write-Information -MessageData ":: Install Microsoft Visual C++ Redistributables" -InformationAction "Continue"
Import-Module -Name "VcRedist" -Force
Get-VcList | Save-VcRedist -Path $Path | Install-VcRedist -Silent | Out-Null
#endregion
