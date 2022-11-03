#description: Preps a RDS/WVD image for customisation.
#execution mode: Combined
#tags: Prep
<#
    .SYNOPSIS
        Preps a RDS/WVD image for customisation.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs progress to the pipeline log")]
[CmdletBinding()]
param ()

# Ready image
Write-Host "Disable Windows Defender real time scan"
Set-MpPreference -DisableRealtimeMonitoring $true

Write-Host "Disable Windows Store updates"
REG add HKLM\Software\Policies\Microsoft\Windows\CloudContent /v "DisableWindowsConsumerFeatures" /d 1 /t "REG_DWORD" /f
REG add HKLM\Software\Policies\Microsoft\WindowsStore /v "AutoDownload" /d 2 /t "REG_DWORD" /f

Write-Host "Complete: PrepImage."
