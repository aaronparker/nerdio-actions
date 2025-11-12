#description: Configure Windows UI settings
#execution mode: Combined
#tags: UI

# Add registry keys
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "MS Shell Dlg" /t "REG_SZ" /d "Tahoma" /f | Out-Null
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "MS Shell Dlg 2" /t "REG_SZ" /d "Tahoma" /f | Out-Null
