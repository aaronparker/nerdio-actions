$Context.Log("Installing ImageGlass")
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($Context.GetAttachedBinary())`" RUNAPPLICATION=0 ALLUSERS=1 ALLUSERS=1 /quiet"
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
Start-Process @params
$Context.Log("Install complete")

Start-Sleep -Seconds 5
$Context.Log("Removing ImageGlass shortcuts.")
$Shortcuts = @("$Env:Public\Desktop\ImageGlass.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\ImageGlass\ImageGlass' LICENSE.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\ImageGlass\Uninstall ImageGlass*.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
