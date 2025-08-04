$Context.Log("Installing Zoom Workplace")
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
$LogFile = "$Env:SystemRoot\Logs\ImageBuild\ZoomWorkplace.log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($Context.GetAttachedBinary())`" zSilentStart=false zNoDesktopShortCut=true ALLUSERS=1 /quiet /log $LogFile"
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
Start-Process @params
$Context.Log("Install complete")
