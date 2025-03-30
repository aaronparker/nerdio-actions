<#
.SYNOPSIS
Installs all available Windows updates with PSWindowsUpdate.

.DESCRIPTION
This script installs all available Windows updates using the PSWindowsUpdate module.
It first deletes the policy setting created by MDT and then proceeds to install the updates.
The script uses the Install-WindowsUpdate cmdlet with the necessary parameters to accept all updates,
include Microsoft updates, and ignore reboot requirements.

.PARAMETER None

.INPUTS
None. You cannot pipe objects to this script.

.OUTPUTS
The script outputs the Title and Size properties of the installed updates.

.EXAMPLE
.\012_WindowsUpdate.ps1
Installs all available Windows updates.

.NOTES
Requires the PSWindowsUpdate module to be installed.
#>

#description: Installs all available Windows updates with PSWindowsUpdate
#execution mode: IndividualWithRestart
#tags: Update, Image
#Requires -Modules PSWindowsUpdate

# Delete the policy setting created by MDT
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /f | Out-Null

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
