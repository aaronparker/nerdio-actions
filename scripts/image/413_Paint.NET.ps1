#description: Installs the latest version of Paint.NET 64-bit with automatic update disabled
#execution mode: Combined
#tags: Evergreen, Paint.NET
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Paint.NET"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "PaintDotNetOfflineInstaller" | `
        Where-Object { $_.Architecture -eq "x64" -and $_.URI -match "winmsi" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    $params = @{
        Path            = $OutFile.FullName
        DestinationPath = $Path
    }
    Expand-Archive @params
}
catch {
    throw $_
}

try {
    $Installer = Get-ChildItem -Path $Path -Include "paint*.msi" -Recurse
    $LogFile = "$env:ProgramData\Evergreen\Logs\Paint.NET$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = "$env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($Installer.FullName)`" DESKTOPSHORTCUT=0 CHECKFORUPDATES=0 CHECKFORBETAS=0 /quiet /log $LogFile"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
    }
    $result = Start-Process @params
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}

Start-Sleep -Seconds 5
$Shortcuts = @("$env:Public\Desktop\Paint.NET.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
