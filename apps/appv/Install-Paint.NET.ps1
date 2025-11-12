#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Temp"

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "PaintDotNetOfflineInstaller" | `
    Where-Object { $_.Architecture -eq "x64" -and $_.URI -match "winmsi" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$params = @{
    Path            = $OutFile.FullName
    DestinationPath = $Path
    Force           = $true
    ErrorAction     = "Stop"
}
Expand-Archive @params

$Installer = Get-ChildItem -Path $Path -Include "paint*.msi" -Recurse
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($Installer.FullName)`" DESKTOPSHORTCUT=0 CHECKFORUPDATES=0 CHECKFORBETAS=0 /quiet"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:Public\Desktop\Paint.NET.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
