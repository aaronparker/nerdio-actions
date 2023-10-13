#description: Disables Windows Update
#execution mode: Combined
#tags: Update, Image

$RegPath = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU"
if (-not (Test-Path -Path $RegPath)) { New-Item -Path $RegPath -Force }
Set-ItemProperty -Path $RegPath -Name NoAutoUpdate -Value 1
Set-ItemProperty -Path $RegPath -Name AUOptions -Value 3
