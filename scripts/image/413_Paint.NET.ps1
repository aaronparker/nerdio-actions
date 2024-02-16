#description: Installs the latest version of Paint.NET 64-bit with automatic update disabled
#execution mode: Combined
#tags: Evergreen, Paint.NET
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Paint.NET"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "PaintDotNetOfflineInstaller" | `
    Where-Object { $_.Architecture -eq "x64" -and $_.URI -match "winmsi" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

$params = @{
    Path            = $OutFile.FullName
    DestinationPath = $Path
    ErrorAction     = "Stop"
}
Expand-Archive @params

Write-Information -MessageData ":: Install Paint.NET" -InformationAction "Continue"
$Installer = Get-ChildItem -Path $Path -Include "paint*.msi" -Recurse
$LogFile = "$Env:ProgramData\Nerdio\Logs\Paint.NET$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($Installer.FullName)`" DESKTOPSHORTCUT=0 CHECKFORUPDATES=0 CHECKFORBETAS=0 /quiet /log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:Public\Desktop\Paint.NET.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
