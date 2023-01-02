#description: Installs the latest version of Greenshot
#execution mode: Combined
#tags: Evergreen, Greenshot
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Greenshot"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "Greenshot" | Where-Object { $_.Architecture -eq "x86" -and $_.Uri -match "Greenshot-INSTALLER-*" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    $LogFile = "$env:ProgramData\Evergreen\Logs\Greenshot$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /LOG=$LogFile"
        NoNewWindow  = $true
        Wait         = $false
        PassThru     = $true
    }
    $result = Start-Process @params
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}

Start-Sleep -Seconds 5
Get-Process -ErrorAction "SilentlyContinue" | `
    Where-Object { $_.Path -like "$env:ProgramFiles\Greenshot\*" } | `
    Stop-Process -Force -ErrorAction "SilentlyContinue"
$Shortcuts = @("$env:Public\Desktop\Greenshot.lnk",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Greenshot\License.txt.lnk",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Greenshot\Readme.txt.lnk",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Greenshot\Uninstall Greenshot.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
