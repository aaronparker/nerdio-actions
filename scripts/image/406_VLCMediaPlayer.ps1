#description: Installs the latest VLC media player 64-bit
#execution mode: Combined
#tags: Evergreen, VLC
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\VLC\MediaPlayer"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "VideoLanVlcPlayer" | Where-Object { $_.Architecture -eq "x64" -and $_.Type -eq "MSI" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    $LogFile = "$Env:ProgramData\Evergreen\Logs\VlcMediaPlayer$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($OutFile.FullName)`" ALLUSERS=1 /quiet /log $LogFile"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
}
catch {
    throw $_
}

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\VideoLAN\VLC\VideoLAN website.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\VideoLAN\VLC\Release Notes.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\VideoLAN\VLC\Documentation.lnk",
    "$Env:Public\Desktop\VLC media player.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
