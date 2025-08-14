$Context.Log("Installing Microsoft Azure CLI")
$params = @{
    FilePath     = $Context.GetAttachedBinary()
    ArgumentList = "/install /quiet /norestart ALLUSERS=1"
    Wait         = $true
    PassThru     = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
$Context.Log("Install complete. Return code: $($result.ExitCode)")
