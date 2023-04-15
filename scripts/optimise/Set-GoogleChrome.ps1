#description: Set Google Chrome optimisations. These options can be set via Group Policy instead
#execution mode: Combined
#tags: Google, Chrome, Optimise

# Disable update tasks - assuming we're installing on a gold image or updates will be managed
Get-Service -Name "gupdate*" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
Get-Service -Name "GoogleChromeElevationService" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
Get-ScheduledTask -TaskName "GoogleUpdateTaskMachine*" | Unregister-ScheduledTask -Confirm:$false -ErrorAction "SilentlyContinue"

# Disable Software Reporting Tool
Set-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "ChromeCleanupEnabled" -Type "DWord" -Value 0
Set-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "ChromeCleanupReportingEnabled" -Type "DWord" -Value 0
