#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Temp"

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "Greenshot" | Where-Object { $_.Type -eq "exe" -and $_.InstallerType -eq "Default" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /TASKS= /FORCECLOSEAPPLICATIONS /LOGCLOSEAPPLICATIONS /NORESTARTAPPLICATIONS"
    NoNewWindow  = $true
    Wait         = $false
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params

# Close Greenshot
Start-Sleep -Seconds 20
Get-Process -ErrorAction "SilentlyContinue" | `
    Where-Object { $_.Path -like "$Env:ProgramFiles\Greenshot\*" } | `
    Stop-Process -Force -ErrorAction "SilentlyContinue"

# Remove unneeded shortcuts
$Shortcuts = @("$Env:Public\Desktop\Greenshot.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\Greenshot\License.txt.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\Greenshot\Readme.txt.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\Greenshot\Uninstall Greenshot.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
