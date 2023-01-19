#description: Downloads the Microsoft Virtual Desktop Optimization Tool and optimises the OS. Ensure 014_RolesFeatures.ps1 and 015_Customise.ps1 are run
#execution mode: Combined
#tags: Image, Optimise
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Citrix\Optimizer"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    # Download Microsoft Virtual Desktop Optimization Tool
    $App = Get-EvergreenApp -Name "MicrosoftVdot" | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    # Run Microsoft Virtual Desktop Optimization Tool
    Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force
    $Installer = Get-ChildItem -Path $Path -Recurse -Include "Windows_VDOT.ps1"
    Push-Location -Path $Installer.Directory
    $params = @{
        Optimizations = "ScheduledTasks", "Autologgers", "Services", "NetworkOptimizations"
        AcceptEULA    = $true
        Restart       = $false
        Verbose       = $false
    }
    & $Installer.FullName @params
    Pop-Location
}
catch {
    throw $_
}
