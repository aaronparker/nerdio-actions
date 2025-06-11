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

# Delete the policy setting created by MDT
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /f *> $null

# Install updates
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
Install-WindowsUpdate @params | Select-Object -Property "Title", "Size"
