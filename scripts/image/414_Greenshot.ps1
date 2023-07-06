#description: Installs the latest version of Greenshot
#execution mode: Combined
#tags: Evergreen, Greenshot
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Greenshot"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "Greenshot" | Where-Object { $_.Architecture -eq "x86" -and $_.Uri -match "Greenshot-INSTALLER-*" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}

try {
    Write-Information -MessageData ":: Install Greenshot" -InformationAction "Continue"
    $LogFile = "$Env:ProgramData\Nerdio\Logs\Greenshot$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /TASKS= /FORCECLOSEAPPLICATIONS /LOGCLOSEAPPLICATIONS /NORESTARTAPPLICATIONS /LOG=$LogFile"
        NoNewWindow  = $true
        Wait         = $false
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
}
catch {
    throw $_.Exception.Message
}

Start-Sleep -Seconds 5
Get-Process -ErrorAction "SilentlyContinue" | `
    Where-Object { $_.Path -like "$Env:ProgramFiles\Greenshot\*" } | `
    Stop-Process -Force -ErrorAction "SilentlyContinue"
$Shortcuts = @("$Env:Public\Desktop\Greenshot.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\Greenshot\License.txt.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\Greenshot\Readme.txt.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\Greenshot\Uninstall Greenshot.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
