$Context.Log("Installing Microsoft OneDrive")
$params = @{
    FilePath     = $Context.GetAttachedBinary()
    ArgumentList = "/install /quiet /norestart"
    Wait         = $true
    PassThru     = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
$Context.Log("Install complete. Return code: $($result.ExitCode)")
