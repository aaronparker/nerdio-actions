#description: Installs the latest Notepad++ 64-bit with automatic updates disabled.
#execution mode: Combined
#tags: Evergreen, Notepad++
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\NotepadPlusPlus"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "NotepadPlusPlus" | Where-Object { $_.Architecture -eq "x64" -and $_.Type -eq "exe" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

Write-Information -MessageData ":: Install Notepad++" -InformationAction "Continue"
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/S"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Continue"
}
$result = Start-Process @params
Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"

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
