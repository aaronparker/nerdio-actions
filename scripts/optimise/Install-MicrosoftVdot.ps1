#description: Downloads the Microsoft Virtual Desktop Optimization Tool and optimises the OS. Ensure 014_RolesFeatures.ps1 and 015_Customise.ps1 are run
#execution mode: Combined
#tags: Image, Optimise
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Vdot"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"
$LogFile = Get-LogFile

# Download Microsoft Virtual Desktop Optimization Tool
$App = Get-EvergreenApp -Name "MicrosoftVdot" | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
Write-LogFile -Message "Microsoft Virtual Desktop Optimization Tool $($App.Version) downloaded to: $($OutFile.FullName)"
Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force
$Installer = Get-ChildItem -Path $Path -Recurse -Include "Windows_VDOT.ps1"
Write-LogFile -Message "Starting Microsoft Virtual Desktop Optimization Tool from: $($Installer.FullName)"

# Compress the log files - the Virtual Desktop Optimization Tool will delete .log files
Write-LogFile -Message "Compressing log files to $($LogFile.Path)\ImageBuildLogs.zip"
Compress-Archive -Path "$LogFile.Path\*.*" -DestinationPath "$($LogFile.Path)\ImageBuildLogs.zip" -Force -ErrorAction "SilentlyContinue"

# Run Microsoft Virtual Desktop Optimization Tool
# Other options for Optimizations:
# Optimizations - "All", "WindowsMediaPlayer", "AppxPackages", "ScheduledTasks", "DefaultUserSettings", "LocalPolicy", "Autologgers", "Services", "NetworkOptimizations", "DiskCleanup"
# AdvancedOptimizations - "All", "Edge", "RemoveLegacyIE", "RemoveOneDrive"
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
Expand-Archive -Path "$($LogFile.Path)\ImageBuildLogs.zip" -DestinationPath $LogFile.Path -Force -ErrorAction "SilentlyContinue"
Remove-Item -Path "$($LogFile.Path)\ImageBuildLogs.zip" -Force -ErrorAction "SilentlyContinue"
Write-LogFile -Message "Extracted logs from $($LogFile.Path)\ImageBuildLogs.zip to $($LogFile.Path)"
