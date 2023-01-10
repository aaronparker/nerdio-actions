#description: Enables screen capture protection on AVD session hosts
#execution mode: Combined
#tags: Screen capture, Image
<#
This configuration should be implemented via GPO
https://learn.microsoft.com/en-us/azure/virtual-desktop/screen-capture-protection
#>

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v "fEnableScreenCaptureProtect" /t "REG_DWORD" /d 1 /f | Out-Null
