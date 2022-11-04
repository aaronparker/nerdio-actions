#description: Installs Windows Updates
#execution mode: IndividualWithRestart
#tags: Update

#region Restart if running in a 32-bit session
if (!([System.Environment]::Is64BitProcess)) {
    if ([System.Environment]::Is64BitOperatingSystem) {
        $Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$($MyInvocation.MyCommand.Definition)`""
        $ProcessPath = $(Join-Path -Path $Env:SystemRoot -ChildPath "\Sysnative\WindowsPowerShell\v1.0\powershell.exe")
        $params = @{
            FilePath     = $ProcessPath
            ArgumentList = $Arguments
            Wait         = $True
            WindowStyle  = "Hidden"
        }
        Start-Process @params
        exit 0
    }
}
#endregion

# Delete the policy setting created by MDT
REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /f


Install-PackageProvider -Name "NuGet" -MinimumVersion 2.8.5.208 -Force
Set-PSRepository -Name "PSGallery" -InstallationPolicy "Trusted"
Install-Module -Name "PSWindowsUpdate" -Force
Import-Module -Name "PSWindowsUpdate"
Install-WindowsUpdate -AcceptAll -MicrosoftUpdate -IgnoreReboot
