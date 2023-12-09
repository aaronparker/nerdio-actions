#description: Runs a Microsoft Defender antivirus quick scan. Use in a desktop image to ensure the scan data is up to date
#execution mode: Combined
#tags: Antivirus, Image

Update-MpSignature -UpdateSource "MicrosoftUpdateServer"
Start-MpScan -ScanType "FullScan"
