$Context.Log("Installing Visual Studio Code")
$params = @{
    FilePath     = $Context.GetAttachedBinary()
    ArgumentList = "/VERYSILENT /NOCLOSEAPPLICATIONS /NORESTARTAPPLICATIONS /NORESTART /SP- /SUPPRESSMSGBOXES /MERGETASKS=!runcode"
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
Start-Process @params
$Context.Log("Install complete")
