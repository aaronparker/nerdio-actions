#description: Installs the latest Zoom Meetings VDI client
#execution mode: Combined
#tags: Evergreen, Zoom
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Zoom\Meetings"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Download Zoom
Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "ZoomVDI" | Where-Object { $_.Platform -eq "VDIClient" -and $_.Architecture -eq "x64" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

Write-Information -MessageData ":: Install Zoom Meetings" -InformationAction "Continue"
$LogFile = "$Env:ProgramData\Nerdio\Logs\ZoomMeetings$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" zSilentStart=false zNoDesktopShortCut=true ALLUSERS=1 /quiet /log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Continue"
}
$result = Start-Process @params
Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
#endregion
