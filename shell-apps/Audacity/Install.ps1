$params = @{
    FilePath     = $Context.GetAttachedBinary()
    ArgumentList = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /MERGETASKS=`"!desktopicon`""
    Wait         = $true
    PassThru     = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
$Context.Log("Install complete. Return code: $($result.ExitCode)")
