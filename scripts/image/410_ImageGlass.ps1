#description: Installs the latest version of ImageGlass 64-bit
#execution mode: Combined
#tags: Evergreen, ImageGlass
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\ImageGlass"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "ImageGlass" | Where-Object { $_.Architecture -eq "x64" -and $_.Type -eq "msi" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

Write-Information -MessageData ":: Install ImageGlass" -InformationAction "Continue"
$LogFile = "$Env:ProgramData\Nerdio\Logs\ImageGlass$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" RUNAPPLICATION=0 ALLUSERS=1 /quiet /log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:Public\Desktop\ImageGlass.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\ImageGlass\ImageGlass' LICENSE.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\ImageGlass\Uninstall ImageGlass*.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
