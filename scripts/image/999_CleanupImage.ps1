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
Get-ChildItem -Path "$Env:Temp" -Include "*.*" -Recurse | `
    Remove-Item -Force -ErrorAction "SilentlyContinue"

# Remove logs older than 30 days
Get-ChildItem -Path "$Env:ProgramData\Nerdio\Logs" -Include "*.*" -Recurse | `
    Where-Object { ($_.LastWriteTime -lt (Get-Date).AddDays(-30)) -and ($_.psIsContainer -eq $false) } | `
    Remove-Item -Force -ErrorAction "SilentlyContinue"

# Disable Windows Update
# reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f
