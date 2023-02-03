#description: Installs all available Windows updates with PSWindowsUpdate
#execution mode: IndividualWithRestart
#tags: Update, Image
#Requires -Modules PSWindowsUpdate

try {
    # Delete the policy setting created by MDT
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /f | Out-Null

    # Install updates
    Write-Information -MessageData ":: Installing Windows updates" -InformationAction "Continue"
    Import-Module -Name "PSWindowsUpdate"
    Install-WindowsUpdate -AcceptAll -MicrosoftUpdate -IgnoreReboot
}
catch {
    throw $_
}
