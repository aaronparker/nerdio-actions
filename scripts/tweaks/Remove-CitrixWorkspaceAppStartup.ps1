#description: Remove the Citrix Workspace app processes from the Run registry key
#execution mode: Combined
#tags: Citrix

reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "AnalyticsSrv" /f | Out-Null
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "ConnectionCenter" /f | Out-Null
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "Redirector" /f | Out-Null
