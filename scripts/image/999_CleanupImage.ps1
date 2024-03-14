<#
.SYNOPSIS
This script is used to clean up an image by reenabling settings, removing application installers,
and removing logs older than 30 days post image completion.

.DESCRIPTION
The script performs the following actions:
- Removes policies that prevent updates during deployment on Windows 10.
- Removes unnecessary paths in the image, such as "$Env:SystemDrive\Apps" and "$Env:SystemDrive\DeployAgent".
- Clears the Temp directory by removing all items and recreating the directory.
- Deletes logs older than 30 days from the "$Env:ProgramData\Nerdio\Logs" directory.
- Disables Windows Update by modifying the registry.

.NOTES
- This script should be run with administrative privileges.
- The script is specifically designed for use in the Nerdio environment.
- Use caution when modifying the registry as it can have unintended consequences.
#>

#description: Reenables settings, removes application installers, and remove logs older than 30 days post image completion
#execution mode: Combined
#tags: Image

if ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption -like "Microsoft Windows 1*") {
    # Remove policies
    Write-Information -MessageData ":: Remove policies that prevent updates during deployment" -InformationAction "Continue"
    reg delete "HKLM\Software\Policies\Microsoft\WindowsStore" /v "AutoDownload" /f
}

# Remove paths that we should not need to leave around in the image
if (Test-Path -Path "$Env:SystemDrive\Apps") { Remove-Item -Path "$Env:SystemDrive\Apps" -Recurse -Force -ErrorAction "SilentlyContinue" }
if (Test-Path -Path "$Env:SystemDrive\DeployAgent") { Remove-Item -Path "$Env:SystemDrive\DeployAgent" -Recurse -Force -ErrorAction "SilentlyContinue" }

# Remove items from the Temp directory (note that scripts run as SYSTEM)
Remove-Item -Path $Env:Temp -Recurse -Force -Confirm:$false -ErrorAction "SilentlyContinue"
New-Item -Path $Env:Temp -ItemType "Directory" -ErrorAction "SilentlyContinue" | Out-Null

# Remove logs older than 30 days
Get-ChildItem -Path "$Env:ProgramData\Nerdio\Logs" -Include "*.*" -Recurse -ErrorAction "SilentlyContinue" | `
    Where-Object { ($_.LastWriteTime -lt (Get-Date).AddDays(-30)) -and ($_.psIsContainer -eq $false) } | `
    ForEach-Object { Remove-Item -Path $_.FullName -Force -Confirm:$false -ErrorAction "SilentlyContinue" }

# Disable Windows Update
# reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f
