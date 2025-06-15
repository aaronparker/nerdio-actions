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
#execution mode: Combined
#tags: Update, Image
#Requires -Modules PSWindowsUpdate

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

# Delete the policy setting created by MDT
Start-ProcessWithLog -FilePath "$Env:SystemRoot\System32\reg.exe" -ArgumentList "delete HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /f"

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
