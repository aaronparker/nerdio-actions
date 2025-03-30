#description: Downloads the Microsoft Virtual Desktop Optimization Tool and optimises the OS. Ensure 014_RolesFeatures.ps1 and 015_Customise.ps1 are run
#execution mode: IndividualWithRestart
#tags: Image, Optimise
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Vdot"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Download Microsoft Virtual Desktop Optimization Tool
$App = Get-EvergreenApp -Name "MicrosoftVdot" | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

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

# Other options for Optimizations:
# Optimizations - "All", "WindowsMediaPlayer", "AppxPackages", "ScheduledTasks", "DefaultUserSettings", "LocalPolicy", "Autologgers", "Services", "NetworkOptimizations", "DiskCleanup"
# AdvancedOptimizations - "All", "Edge", "RemoveLegacyIE", "RemoveOneDrive"
