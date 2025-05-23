$Context.Log("Installing Audacity")
$params = @{
    FilePath     = $Context.GetAttachedBinary()
    ArgumentList = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /MERGETASKS=`"!desktopicon`""
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
Start-Process @params
$Context.Log("Install complete")
