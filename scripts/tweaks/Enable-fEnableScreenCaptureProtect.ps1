#description: Enables screen capture protection on AVD session hosts
#execution mode: Combined
#tags: Screen capture, Image
<#
https://docs.microsoft.com/en-us/azure/virtual-desktop/security-guide#enable-screen-capture-protection-preview
#>

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v "fEnableScreenCaptureProtect" /t "REG_DWORD" /d 1 /f | Out-Null
