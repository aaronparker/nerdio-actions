$Context.Log("Installing ImageGlass")
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
$LogFile = "$Env:SystemRoot\Logs\ImageBuild\ImageGlass.log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($Context.GetAttachedBinary())`" RUNAPPLICATION=0 ALLUSERS=1 ALLUSERS=1 /quiet /log $LogFile"
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
Start-Process @params
$Context.Log("Install complete")

Start-Sleep -Seconds 5
Write-LogFile -Message "Removing ImageGlass shortcuts."
$Shortcuts = @("$Env:Public\Desktop\ImageGlass.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\ImageGlass\ImageGlass' LICENSE.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\ImageGlass\Uninstall ImageGlass*.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
