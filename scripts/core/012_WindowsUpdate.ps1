<#
    .SYNOPSIS
    Installs all available Windows updates with PSWindowsUpdate.

    .DESCRIPTION
    This script installs all available Windows updates using the PSWindowsUpdate module.
    It first deletes the policy setting created by MDT and then proceeds to install the updates.
    The script uses the Install-WindowsUpdate cmdlet with the necessary parameters to accept all updates,
    include Microsoft updates, and ignore reboot requirements.

    .OUTPUTS
    The script outputs the Title and Size properties of the installed updates.
#>

#description: Installs all available Windows updates with PSWindowsUpdate
#execution mode: IndividualWithRestart
#tags: Update, Image
#Requires -Modules PSWindowsUpdate

# Import the shared functions
$LogPath = "$Env:ProgramData\ImageBuild"
Import-Module -Name "$LogPath\Functions.psm1" -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $LogPath\Functions.psm1"

# Delete the policy setting created by MDT
Write-LogFile -Message "Delete: HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /f *> $null

# Install updates
Write-LogFile -Message "Installing all available Windows updates with PSWindowsUpdate"
Import-Module -Name "PSWindowsUpdate"
$params = @{
    Install              = $true
    Download             = $true
    AcceptAll            = $true
    MicrosoftUpdate      = $true
    IgnoreReboot         = $true
    IgnoreRebootRequired = $true
    IgnoreUserInput      = $true
}
Install-WindowsUpdate @params | Select-Object -Property "Title", "Size" | ForEach-Object {
    Write-LogFile -Message "Installed update: $($_.Title)"
}
