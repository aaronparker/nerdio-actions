#description: Downloads the Microsoft Virtual Desktop Optimization Tool and optimises the OS. Ensure 014_RolesFeatures.ps1 and 015_Customise.ps1 are run
#execution mode: IndividualWithRestart
#tags: Image, Optimise
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Vdot"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

$LogPath = "$Env:ProgramData\ImageBuild"
Import-Module -Name "$LogPath\Functions.psm1" -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $LogPath\Functions.psm1"

#region Script logic
# Download Microsoft Virtual Desktop Optimization Tool
$App = Get-EvergreenApp -Name "MicrosoftVdot" | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
Write-LogFile -Message "Microsoft Virtual Desktop Optimization Tool $($App.Version) downloaded to: $($OutFile.FullName)"
Write-LogFile -Message "Starting Microsoft Virtual Desktop Optimization Tool from: $($Installer.FullName)"

# Compress the log files - the Virtual Desktop Optimization Tool will delete .log files
Compress-Archive -Path $LogPath -DestinationPath "$LogPath\ImageBuildLogs.zip" -Force -ErrorAction "SilentlyContinue"

# Run Microsoft Virtual Desktop Optimization Tool
Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force
$Installer = Get-ChildItem -Path $Path -Recurse -Include "Windows_VDOT.ps1"
Push-Location -Path $Installer.Directory
$params = @{
    Optimizations         = "WindowsMediaPlayer", "ScheduledTasks", "LocalPolicy", "Autologgers", "Services", "NetworkOptimizations", "DiskCleanup"
    AdvancedOptimizations = "Edge"
    AcceptEULA            = $true
    Restart               = $false
    Verbose               = $false
}
& $Installer.FullName @params
Pop-Location

# Extract the logs back to the log path and remove the zip file
Expand-Archive -Path "$LogPath\ImageBuildLogs.zip" -DestinationPath $LogPath -Force -ErrorAction "SilentlyContinue"
Remove-Item -Path "$LogPath\ImageBuildLogs.zip" -Force -ErrorAction "SilentlyContinue"

# Other options for Optimizations:
# Optimizations - "All", "WindowsMediaPlayer", "AppxPackages", "ScheduledTasks", "DefaultUserSettings", "LocalPolicy", "Autologgers", "Services", "NetworkOptimizations", "DiskCleanup"
# AdvancedOptimizations - "All", "Edge", "RemoveLegacyIE", "RemoveOneDrive"
