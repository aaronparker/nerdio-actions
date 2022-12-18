#description: Installs Microsoft Virtual Desktop Optimizations for Windows 10 20H2 (clone and edit to customize)
#execution mode: IndividualWithRestart
#tags: Nerdio
<#
Notes:
This script uses the Virtual Desktop Optimization tool, found here: 
https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool
to remove default apps, disable tasks and services, and alter registry values in order to optimizze
windows for VDI. This script is written in a way to allow alteration to deviate from the default settings
specified in the original optimization tool.

To use this script:
Customize the values below as desired.
- Ensure this script is run for version 2009 / 20H2 
#>

# ================ Customize the Services To remove here. If a service is desired, delete the line.
$Services = @"
autotimesvc
BcastDVRUserService
defragsvc
DiagSvc
DiagTrack
DPS
DusmSvc
icssvc
lfsvc
MapsBroker
MessagingService
OneSyncSvc
PimIndexMaintenanceSvc
Power
SEMgrSvc
SmsRouter
SysMain
TabletInputService
WdiSystemHost
WerSvc
XblAuthManager
XblGameSave
XboxGipSvc
XboxNetApiSvc
"@

# ================== Customize User settings here. Please ensure to use correct JSON formatting
$DefaultUserSettings = @"
[
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer",
        "KeyName": "ShellState",
        "PropertyType": "BINARY",
        "PropertyValue": "0x24,0x00,0x00,0x00,0x3C,0x28,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00",
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
        "KeyName": "IconsOnly",
        "PropertyType": "DWORD",
        "PropertyValue": 1,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
        "KeyName": "ListviewAlphaSelect",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
        "KeyName": "ListviewShadow",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
        "KeyName": "ShowCompColor",
        "PropertyType": "DWORD",
        "PropertyValue": 1,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
        "KeyName": "ShowInfoTip",
        "PropertyType": "DWORD",
        "PropertyValue": 1,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
        "KeyName": "TaskbarAnimations",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VisualEffects",
        "KeyName": "VisualFXSetting",
        "PropertyType": "DWORD",
        "PropertyValue": 3,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\DWM",
        "KeyName": "EnableAeroPeek",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\DWM",
        "KeyName": "AlwaysHiberNateThumbnails",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Control Panel\\Desktop",
        "KeyName": "DragFullWindows",
        "PropertyType": "STRING",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Control Panel\\Desktop",
        "KeyName": "FontSmoothing",
        "PropertyType": "STRING",
        "PropertyValue": 2,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Control Panel\\Desktop",
        "KeyName": "UserPreferencesMask",
        "PropertyType": "BINARY",
        "PropertyValue": "0x90,0x32,0x07,0x80,0x10,0x00,0x00,0x00",
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Control Panel\\Desktop\\WindowMetrics",
        "KeyName": "MinAnimate",
        "PropertyType": "STRING",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\StorageSense\\Parameters\\StoragePolicy",
        "KeyName": "01",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "KeyName": "SubscribedContent-338393Enabled",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "KeyName": "SubscribedContent-338393Enabled",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "KeyName": "SubscribedContent-353696Enabled",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "KeyName": "SubscribedContent-338388Enabled",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "KeyName": "SubscribedContent-338389Enabled",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "KeyName": "SystemPaneSuggestionsEnabled",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Control Panel\\International\\User Profile",
        "KeyName": "HttpAcceptLanguageOptOut",
        "PropertyType": "DWORD",
        "PropertyValue": 1,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications\\Microsoft.Windows.Photos_8wekyb3d8bbwe",
        "KeyName": "Disabled",
        "PropertyType": "DWORD",
        "PropertyValue": 1,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications\\Microsoft.Windows.Photos_8wekyb3d8bbwe",
        "KeyName": "DisabledByUser",
        "PropertyType": "DWORD",
        "PropertyValue": 1,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications\\Microsoft.SkypeApp_kzf8qxf38zg5c",
        "KeyName": "Disabled",
        "PropertyType": "DWORD",
        "PropertyValue": 1,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications\\Microsoft.SkypeApp_kzf8qxf38zg5c",
        "KeyName": "DisabledByUser",
        "PropertyType": "DWORD",
        "PropertyValue": 1,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications\\Microsoft.YourPhone_8wekyb3d8bbwe",
        "KeyName": "Disabled",
        "PropertyType": "DWORD",
        "PropertyValue": 1,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications\\Microsoft.YourPhone_8wekyb3d8bbwe",
        "KeyName": "DisabledByUser",
        "PropertyType": "DWORD",
        "PropertyValue": 1,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications\\Microsoft.MicrosoftEdge_8wekyb3d8bbwe",
        "KeyName": "Disabled",
        "PropertyType": "DWORD",
        "PropertyValue": 1,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications\\Microsoft.MicrosoftEdge_8wekyb3d8bbwe",
        "KeyName": "DisabledByUser",
        "PropertyType": "DWORD",
        "PropertyValue": 1,
        "SetProperty": "True"
    },    
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications\\Microsoft.549981C3F5F10_8wekyb3d8bbwe",
        "KeyName": "Disabled",
        "PropertyType": "DWORD",
        "PropertyValue": 1,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications\\Microsoft.549981C3F5F10_8wekyb3d8bbwe",
        "KeyName": "DisabledByUser",
        "PropertyType": "DWORD",
        "PropertyValue": 1,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\InputPersonalization",
        "KeyName": "RestrictImplicitInkCollection",
        "PropertyType": "DWORD",
        "PropertyValue": 1,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\InputPersonalization",
        "KeyName": "RestrictImplicitTextCollection",
        "PropertyType": "DWORD",
        "PropertyValue": 1,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\InputPersonalization\\TrainedDataStore",
        "KeyName": "HarvestContacts",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Personalization\\Settings",
        "KeyName": "AcceptedPrivacyPolicy",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\UserProfileEngagement",
        "KeyName": "ScoobeSystemSettingEnabled",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\SearchSettings",
        "KeyName": "IsAADCloudSearchEnabled",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\SearchSettings",
        "KeyName": "IsDeviceSearchHistoryEnabled",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    },
    {
        "HivePath": "HKLM:\\VDOT_TEMP\\Software\\Microsoft\\Windows\\CurrentVersion\\SearchSettings",
        "KeyName": "IsMSACloudSearchEnabled",
        "PropertyType": "DWORD",
        "PropertyValue": 0,
        "SetProperty": "True"
    }
]
"@


# ================== Customize AutoLoggers To remove here. If a log is desire, delete the line.
$AutoLoggers = @"
AppModel
CloudExperienceHostOOBE
DiagLog
ReadyBoot
WDIContextLog
WiFiDriverIHVSession
WiFiSession
WinPhoneCritical
"@

# ================== Customize scheduled tasks to remove here. If a scheduled task is disired, remove the line.
$ScheduledTasks = @"
BgTaskRegistrationMaintenanceTask
Consolidator
Diagnostics
FamilySafetyMonitor
FamilySafetyRefreshTask
MapsToastTask
*Compatibility*
Microsoft-Windows-DiskDiagnosticDataCollector
*MNO*
NotificationTask
PerformRemediation
ProactiveScan
ProcessMemoryDiagnosticEvents
Proxy
QueueReporting
RecommendedTroubleshootingScanner
ReconcileLanguageResources
RegIdleBackup
RunFullMemoryDiagnostic
Scheduled
ScheduledDefrag
SilentCleanup
SpeechModelDownloadTask
Sqm-Tasks
SR
StartupAppTask
SyspartRepair
UpdateLibrary
WindowsActionDialog
WinSAT
XblGameSaveTask
"@


# =========================== Logic Code to use previously specified values.
# variables
$WinVersion = '2009'

# Download repo for WVD optimizations
mkdir C:\wvdtemp\Optimize_sa\optimize -Force

Invoke-WebRequest `
    -Uri "https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip" `
    -OutFile "C:\wvdtemp\Optimize_sa\optimize.zip"

Expand-Archive -Path "C:\wvdtemp\Optimize_sa\optimize.zip" -DestinationPath "C:\wvdtemp\Optimize_sa\optimize\"

# Remove default json files 
Remove-Item -Path "C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\$WinVersion\ConfigurationFiles\AppxPackages.json" -Force
Remove-Item -Path "C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\$WinVersion\ConfigurationFiles\Autologgers.Json" -Force
Remove-Item -Path "C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\$WinVersion\ConfigurationFiles\DefaultUserSettings.json" -Force
Remove-Item -Path "C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\$WinVersion\ConfigurationFiles\ScheduledTasks.json" -Force
Remove-Item -Path "C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\$WinVersion\ConfigurationFiles\Services.json" -Force

# Build JSON and txt Configuration Files - These are built here according to the hash table variables specified above.

#Autologgers JSON
$AutoLoggers = ($AutoLoggers -split "`n").Trim() | ForEach-Object {
    $LogHash = @{ }
    $BaseKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\'
    Switch ($_) {
        AppModel {
            $Description = "Used by Packaging, deployment, and query of Windows Store apps. Especially on non-persistent VDI, we tightly control what apps are installed and available, and normally don’t let users change the configuration.  Persistent VDI would be a different story.  If you allow reconfiguration of UWP apps, remove this item." 
            $URL = "https://docs.microsoft.com/en-us/windows/win32/api/appmodel/"
            $Disable = $True
        }
        CloudExperienceHostOOBE {
            $Description = '“Cloud Experience Host” is an application used while joining the workplace environment or Azure AD for rendering the experience when collecting your company-provided credentials. Once you enroll your device to your workplace environment or Azure AD, your organization will be able to manage your PC and collect information about you (including your location). It might add or remove apps or content, change settings, disable features, prevent you from removing your company account, or reset your PC.”. The OOBE part means “out-of-box experience”.  This trace records events around domain or Azure AD join.  Normally provisioned VDI VMs are already joined, so this logging is unnecessary.' 
            $URL = "https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-how-it-works-technology#cloud-experience-host"
            $Disable = $True
        }
        DiagLog {
            $Description = 'A log generated by the Diagnostic Policy Service, which is documented here.  “The Diagnostic Policy Service enables problem detection, troubleshooting and resolution for Windows components. If this service is stopped, diagnostics will no longer function”.  Problem detection in VDI rarely takes place with production machines, but usually happens on machines in a private pool dedicated to troubleshooting.  Windows diagnostics are usually not helpful with VDI.' 
            $URL = "https://docs.microsoft.com/en-us/windows-server/security/windows-services/security-guidelines-for-disabling-system-services-in-windows-server"
            $Disable = $True
        }
        ReadyBoot {
            $Description = '“ReadyBoot is boot acceleration technology that maintains an in-RAM cache used to service disk reads faster than a slower storage medium such as a disk drive”.  VDI does not use “normal” computer disk devices, but usually segments of a shared storage medium.  ReadyBoot and other optimizations designed to assist normal disk devices do not have equivalent effects on shared storage devices.  And further, for non-persistent VDI, 99.999% of computer state is discarded when the user logs off.  This includes any optimizations performed by the OS during runtime.  Therefore, why allow Windows “normal” optimizations when all that computer and I/O work will be discarded at logoff for NP VDI?  For persistent, the choice is yours.  Another consideration is again, pooled VDI.  The users will normally not log into the same VM twice.  Therefore, any RAM caching of predicted I/O will have unknown impact because the underlying disk extent being utilized for that logon session will be different from session to session.' 
            $URL = "https://docs.microsoft.com/en-us/previous-versions/windows/desktop/xperf/readyboot-analysis"
            $Disable = $True
        }
        WDIContextLog {
            $Description = 'This is a startup trace that runs all the time, with these loggers: "Microsoft-Windows-Kernel-PnP":0x48000:0x4+"Microsoft-Windows-Kernel-WDI":0x100000000:0xff+"Microsoft-Windows-Wininit":0x20000:0x4+"Microsoft-Windows-Kernel-BootDiagnostics":0xffffffffffffffff:0x4+"Microsoft-Windows-Kernel-Power":0x1:0x4+"Microsoft-Windows-Winlogon":0x20000:0x4+"Microsoft-Windows-Shell-Core":0x6000000:0x4 On my clean state VM, this trace is running and using a very small amount of resources.  Current buffers are 4, buffer size is 16.  Those numbers reflect the amount of physical RAM reserved for this trace.  Because my VM does not use WLAN, AKA “wireless”, this trace is doing nothing for my VM now, and will not as long as I do not use wireless.  Therefore the recommendation to disable this trace and free these resources.' 
            $URL = "https://docs.microsoft.com/en-us/windows-hardware/drivers/network/wifi-universal-driver-model"
            $Disable = $True
        }
        WiFiDriverIHVSession {
            $Description = 'This log is a container for “user-initiated feedback” for wireless networking (Wi-Fi).  If the VMs were to emulate wireless networking, you might just leave this one alone.  Also, this trace is enabled by default, but not run until triggered, presumably from a user-initiated feedback for a wireless issue.  The Windows diagnostics would run, gather some information from the current system including an event trace, and then send that information to Microsoft.' 
            $URL = "https://docs.microsoft.com/en-us/windows-hardware/drivers/network/user-initiated-feedback-normal-mode"
            $Disable = $True
        }
        WiFiSession {
            $Description = 'Not documented, but not hard to understand.  This is another diagnostic log for the Windows Diagnostics.  If your VMs are not using Wi-Fi, this log is not needed.  You could though leave this alone as it would almost never be started unless a user started a troubleshooter, and troubleshooters are usually disabled in VDI environments.' 
            $URL = "N/A"
            $Disable = $True
        }
        WinPhoneCritical {
            $Description = 'Not documented, but not hard to determine its use: diagnostics for phone. If not using or allowing phones to be attached to your VMs, no need to leave a trace enabled that will never be used.  Or just leave this one alone.' 
            $URL = "N/A"
            $Disable = $True
        }
    }
    $LogHash += @{
        KeyName     = "$BaseKey" + "$_" + "\"
        Description = $Description
        URL         = $URL
        Disabled    = $Disable
    }
    [PSCustomObject]$LogHash
} | ConvertTo-Json
$AutoLoggers | Out-File C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\$WinVersion\ConfigurationFiles\Autologgers.Json

# Scheduled Tasks JSON
$ScheduledTasks = ($ScheduledTasks -split "`n").Trim()
$ScheduledTasksJson = $ScheduledTasks | ForEach-Object { [PSCustomObject] @{'ScheduledTask' = $_; 'VDIState' = 'Disabled'; 'Description' = (Get-ScheduledTask $_ -ErrorAction SilentlyContinue).Description } } | ConvertTo-Json
$ScheduledTasksJson | Out-File C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\$WinVersion\ConfigurationFiles\ScheduledTasks.json
 
#Services JSON
$Services = ($Services -split "`n").Trim()
$ServicesJson = $Services | ForEach-Object { [PSCustomObject]@{Name = $_; 'VDIState' = 'Disabled' ; 'Description' = (Get-Service $_ -ErrorAction SilentlyContinue).DisplayName } } | ConvertTo-Json
$ServicesJson | Out-File C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\$WinVersion\ConfigurationFiles\Services.json

# Create Default User Settings JSON
$DefaultUserSettings | Out-File C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\$WinVersion\ConfigurationFiles\DefaultUserSettings.Json

# run the Optimize Script with newly created JSON files 
C:\wvdtemp\Optimize_sa\optimize\Virtual-Desktop-Optimization-Tool-main\Windows_VDOT.ps1 -Optimizations All -Verbose -AcceptEula

# Clean up Temp Folder
Remove-Item C:\WVDTemp\Optimize_sa\ -Recurse -Force

# End Logging
Stop-Transcript
$VerbosePreference = $SaveVerbosePreference
