#description: Installs Windows Updates
#execution mode: IndividualWithRestart
#tags: Update
#Requires -Modules PSWindowsUpdate

try {
    # Delete the policy setting created by MDT
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /f

    # Install updates
    Import-Module -Name "PSWindowsUpdate"
    Install-WindowsUpdate -AcceptAll -MicrosoftUpdate -IgnoreReboot
}
catch {
    throw $_.Exception.Message
}
