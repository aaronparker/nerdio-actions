#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Temp"

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "NotepadPlusPlus" | Where-Object { $_.Architecture -eq "x64" -and $_.Type -eq "exe" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/S"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params

# Disable updater
$UpdaterPath = "$Env:ProgramFiles\Notepad++\updater"
$RenamePath = "$Env:ProgramFiles\Notepad++\updater.disabled"
if (Test-Path -Path $UpdaterPath) {
    if (Test-Path -Path $RenamePath) {
        Remove-Item -Path $RenamePath -Recurse -Force -ErrorAction "SilentlyContinue"
    }
    Rename-Item -Path $UpdaterPath -NewName "updater.disabled" -Force -ErrorAction "SilentlyContinue"
}
#endregion
