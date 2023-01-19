#description: Installs the latest version of ShareX
#execution mode: Combined
#tags: Evergreen, ShareX
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\ShareX"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "ShareX" | Where-Object { $_.Type -eq "exe" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    $LogFile = "$Env:ProgramData\Evergreen\Logs\ShareX$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /TASKS= /FORCECLOSEAPPLICATIONS /LOGCLOSEAPPLICATIONS /NORESTARTAPPLICATIONS /LOG=$LogFile"
        NoNewWindow  = $true
        Wait         = $false
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    $result.ExitCode
}
catch {
    throw $_
}

Start-Sleep -Seconds 10
Get-Process -ErrorAction "SilentlyContinue" | `
    Where-Object { $_.Path -like "$Env:ProgramFiles\ShareX\*" } | `
    Stop-Process -Force -ErrorAction "SilentlyContinue"
$Shortcuts = @("$Env:Public\Desktop\ShareX.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\ShareX\Uninstall ShareX.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
