#description: Uninstalls the supported Microsoft Visual C++ Redistributables
#execution mode: Combined
#tags: Uninstall, VcRedist, Microsoft
#Requires -Modules VcRedist

#region Script logic
New-Item -Path "$env:ProgramData\NerdioManager\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "VcRedist" -Force
    Get-InstalledVcRedist | Uninstall-VcRedist -Confirm:$false -ErrorAction "SilentlyContinue"
}
catch {
    Write-Warning -Message "Failed to uninstall with error: $($_.Exception.Message)"
}
#endregion
