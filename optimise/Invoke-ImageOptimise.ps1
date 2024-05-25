<#
    Basic optimisations for non-desktop images
#>

# Disable consumer features
reg add "HKLM\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /d 1 /t "REG_DWORD" /f | Out-Null

# Enable time zone redirection
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fEnableTimeZoneRedirection /t REG_DWORD /d 1 /f

# Delete the policy setting created by MDT
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /f | Out-Null

# Trust the PSGallery for modules
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.208" -Force -ErrorAction "SilentlyContinue"
Install-PackageProvider -Name "PowerShellGet" -MinimumVersion "2.2.5" -Force -ErrorAction "SilentlyContinue"
foreach ($Repository in "PSGallery") {
    if (Get-PSRepository | Where-Object { $_.Name -eq $Repository -and $_.InstallationPolicy -ne "Trusted" }) {
        Set-PSRepository -Name $Repository -InstallationPolicy "Trusted"
    }
}

# Install the Evergreen module; https://github.com/aaronparker/Evergreen
# Install the VcRedist module; https://docs.stealthpuppy.com/vcredist/
foreach ($module in "Evergreen", "PSWindowsUpdate") {
    $installedModule = Get-Module -Name $module -ListAvailable -ErrorAction "SilentlyContinue" | `
        Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } -ErrorAction "SilentlyContinue" | `
        Select-Object -First 1
    $publishedModule = Find-Module -Name $module -ErrorAction "SilentlyContinue"
    if (($null -eq $installedModule) -or ([System.Version]$publishedModule.Version -gt [System.Version]$installedModule.Version)) {
        $params = @{
            Name               = $module
            SkipPublisherCheck = $true
            Force              = $true
            ErrorAction        = "Stop"
        }
        Install-Module @params
    }
}

# Install updates
# Import-Module -Name "PSWindowsUpdate"
# Install-WindowsUpdate -AcceptAll -MicrosoftUpdate -IgnoreReboot -IgnoreRebootRequired | Select-Object -Property "Title", "Size"

# Regional settings
[System.String] $Language = "en-AU"
[System.String] $TimeZone = "AUS Eastern Standard Time"
Import-Module -Name "International"
Set-TimeZone -Name $TimeZone
Set-Culture -CultureInfo $Language
Set-WinSystemLocale -SystemLocale $Language
Set-WinUILanguageOverride -Language $Language
Set-WinUserLanguageList -LanguageList $Language -Force
$RegionInfo = New-Object -TypeName "System.Globalization.RegionInfo" -ArgumentList $Language
Set-WinHomeLocation -GeoId $RegionInfo.GeoId
Set-SystemPreferredUILanguage -Language $Language

# Remove the FSLogix agent
$FsLogix = Get-ChildItem -Path "$Env:ProgramData\Package Cache" -Recurse -Include "FSLogixAppsSetup.exe"
foreach ($File in $FsLogix) {
    $params = @{
        FilePath     = $File.FullName
        ArgumentList = "/norestart /uninstall /quiet"
        Wait         = $true
        ErrorAction  = "Stop"
    }
    Start-Process @params
}

#region Remove inbox apps
$PackageFamilyNameBlockList = @(
    "7EE7776C.LinkedInforWindows_w1wdnht996qgy",
    "Clipchamp.Clipchamp_yxz26nhyzhsrt",
    "king.com.CandyCrushFriends_kgqvnymyfvs32",
    "king.com.CandyCrushSodaSaga_kgqvnymyfvs32",
    "king.com.FarmHeroesSaga_kgqvnymyfvs32",
    "Microsoft.3DBuilder_8wekyb3d8bbwe",
    "Microsoft.BingFinance_8wekyb3d8bbwe",
    "Microsoft.BingNews_8wekyb3d8bbwe",
    "Microsoft.BingSports_8wekyb3d8bbwe",
    "Microsoft.BingWeather_8wekyb3d8bbwe",
    "Microsoft.GamingApp_8wekyb3d8bbwe",
    "Microsoft.GetHelp_8wekyb3d8bbwe",
    "Microsoft.Getstarted_8wekyb3d8bbwe",
    "Microsoft.HEIFImageExtension_8wekyb3d8bbwe",
    "Microsoft.Messaging_8wekyb3d8bbwe",
    "Microsoft.Microsoft3DViewer_8wekyb3d8bbwe",
    "Microsoft.MicrosoftOfficeHub_8wekyb3d8bbwe",
    "Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe",
    "Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe",
    "Microsoft.MSPaint_8wekyb3d8bbwe",
    "Microsoft.MixedReality.Portal_8wekyb3d8bbwe",
    "Microsoft.Office.Desktop_8wekyb3d8bbwe",
    "Microsoft.Office.Desktop.Access_8wekyb3d8bbwe",
    "Microsoft.Office.Desktop.Excel_8wekyb3d8bbwe",
    "Microsoft.Office.Desktop.Outlook_8wekyb3d8bbwe",
    "Microsoft.Office.Desktop.PowerPoint_8wekyb3d8bbwe",
    "Microsoft.Office.Desktop.Publisher_8wekyb3d8bbwe",
    "Microsoft.Office.Desktop.Word_8wekyb3d8bbwe",
    "Microsoft.OneConnect_8wekyb3d8bbwe",
    "Microsoft.People_8wekyb3d8bbwe",
    "Microsoft.PowerAutomateDesktop_8wekyb3d8bbwe",
    "Microsoft.Print3D_8wekyb3d8bbwe",
    "Microsoft.SkypeApp_kzf8qxf38zg5c",
    "Microsoft.Todos_8wekyb3d8bbwe",
    "Microsoft.VP9VideoExtensions_8wekyb3d8bbwe",
    "Microsoft.WebMediaExtensions_8wekyb3d8bbwe",
    "Microsoft.WebpImageExtension_8wekyb3d8bbwe",
    "Microsoft.Windows.Photos_8wekyb3d8bbwe",
    "Microsoft.WindowsAlarms_8wekyb3d8bbwe",
    "Microsoft.WindowsCamera_8wekyb3d8bbwe",
    "Microsoft.windowscommunicationsapps_8wekyb3d8bbwe",
    "Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe",
    "Microsoft.WindowsMaps_8wekyb3d8bbwe",
    "Microsoft.WindowsPhone_8wekyb3d8bbwe",
    "Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe",
    "Microsoft.XboxApp_8wekyb3d8bbwe",
    "Microsoft.XboxGameOverlay_8wekyb3d8bbwe",
    "Microsoft.XboxGamingOverlay_8wekyb3d8bbwe",
    "Microsoft.YourPhone_8wekyb3d8bbwe",
    "Microsoft.ZuneMusic_8wekyb3d8bbwe",
    "Microsoft.ZuneVideo_8wekyb3d8bbwe",
    "MicrosoftTeams_8wekyb3d8bbwe",
    "Disney.37853FC22B2CE_6rarf9sa4v8jt",
    "SpotifyAB.SpotifyMusic_zpdnekdrzrea0"
)

foreach ($app in $PackageFamilyNameBlockList) {
    $Name = ($app -split "_")[0]
    Get-AppxPackage -Name $Name | Remove-AppxPackage -ErrorAction "SilentlyContinue"
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $Name } | `
        Remove-AppxProvisionedPackage -Online -AllUsers -ErrorAction "SilentlyContinue"
}
#endregion

# Install RDP connection apps
Import-Module -Name "Evergreen"
[System.String] $Path = "$Env:ProgramFiles\RemoteDisplayAnalyzer"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "RDAnalyzer" | Select-Object -First 1
Save-EvergreenApp -InputObject $App -CustomPath $Path -Force -WarningAction "SilentlyContinue" | Out-Null

$App = Get-EvergreenApp -Name "ConnectionExperienceIndicator" | Select-Object -First 1
Save-EvergreenApp -InputObject $App -CustomPath $Path -Force -WarningAction "SilentlyContinue" | Out-Null
