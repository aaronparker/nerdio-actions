#description: Set Microsoft Edge optimisations. These options can be set via Group Policy instead
#execution mode: Combined
#tags: Microsoft, Edge, Optimise

# Disable the First Run Experience
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "HideFirstRunExperience" /d 1 /t "REG_DWORD" /f | Out-Null
