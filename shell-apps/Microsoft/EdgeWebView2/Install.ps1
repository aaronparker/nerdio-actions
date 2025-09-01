$Context.Log("Installing package: $($Context.GetAttachedBinary())")
$params = @{
    FilePath     = $Context.GetAttachedBinary()
    ArgumentList = "/silent /install"
    Wait         = $true
    PassThru     = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
$Context.Log("Install complete. Return code: $($result.ExitCode)")
