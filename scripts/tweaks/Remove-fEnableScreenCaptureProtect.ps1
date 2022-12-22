#description: Enables screen capture protection on AVD session hosts
#execution mode: Combined
#tags: Screen capture, Image
<#
https://docs.microsoft.com/en-us/azure/virtual-desktop/security-guide#enable-screen-capture-protection-preview
#>

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v "fEnableScreenCaptureProtect" /f | Out-Null
