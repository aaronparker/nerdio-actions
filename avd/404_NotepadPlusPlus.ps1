#description: Installs the latest Notepad++ 64-bit with automatic updates disabled.
#execution mode: Combined
#tags: Evergreen, Notepad++
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\NotepadPlusPlus"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "NotepadPlusPlus" | Where-Object { $_.Architecture -eq "x64" -and $_.Type -eq "exe" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = "/S"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $false
    }
    $result = Start-Process @params
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}

try {
    # Disable updater
    $UpdaterPath = "$Env:ProgramFiles\Notepad++\updater"
    $RenamePath = "$Env:ProgramFiles\Notepad++\updater.disabled"
    if (Test-Path -Path $UpdaterPath) {
        if (Test-Path -Path $RenamePath) {
            Remove-Item -Path $RenamePath -Recurse -Force -ErrorAction "SilentlyContinue"
        }
        Rename-Item -Path $UpdaterPath -NewName "updater.disabled" -Force -ErrorAction "SilentlyContinue"
    }
}
catch {
    throw $_.Exception.Message
}
#endregion
