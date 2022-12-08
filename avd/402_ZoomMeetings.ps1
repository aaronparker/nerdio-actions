#description: Installs the latest Zoom Meetings VDI client
#execution mode: Combined
#tags: Evergreen, Zoom
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Zoom\Meetings"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$env:ProgramData\NerdioManager\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    # Download Zoom
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "Zoom" | Where-Object { $_.Platform -eq "VDI" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    $LogFile = "$env:ProgramData\NerdioManager\Logs\ZoomMeetings$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = "$env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($OutFile.FullName)`" ALLUSERS=1 zSilentStart=false zNoDesktopShortCut=true /quiet /log $LogFile"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $false
    }
    $result = Start-Process @params
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}
#endregion
