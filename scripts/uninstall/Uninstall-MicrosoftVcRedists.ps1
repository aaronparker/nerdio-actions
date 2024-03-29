#description: Uninstalls the supported Microsoft Visual C++ Redistributables
#execution mode: Combined
#tags: Uninstall, VcRedist, Microsoft
#Requires -Modules VcRedist

#region Script logic
Import-Module -Name "VcRedist" -Force
Get-InstalledVcRedist | Uninstall-VcRedist -Confirm:$false -ErrorAction "SilentlyContinue"
#endregion
