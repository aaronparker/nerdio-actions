#description: Installs the supported Microsoft Visual C++ Redistributables
#execution mode: Combined
#tags: VcRedist
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\VcRedist"

#region Script logic
# Run tasks/install apps
Write-Verbose -Message "Microsoft Visual C++ Redistributables"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

Write-Verbose -Message "Downloading Microsoft Visual C++ Redistributables"
Save-VcRedist -VcList (Get-VcList) -Path $Path > $Null

Write-Verbose -Message "Installing Microsoft Visual C++ Redistributables"
Install-VcRedist -VcList (Get-VcList) -Path $Path -Silent | Out-Null
#endregion
