#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Temp"

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "VideoLanVlcPlayer" | Where-Object { $_.Architecture -eq "x64" -and $_.Type -eq "MSI" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" ALLUSERS=1 /quiet"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\VideoLAN\VLC\VideoLAN website.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\VideoLAN\VLC\Release Notes.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\VideoLAN\VLC\Documentation.lnk",
    "$Env:Public\Desktop\VLC media player.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
