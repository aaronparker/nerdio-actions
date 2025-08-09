$Context.Log("Installing Visual C++ Redistributable 2022 x64")
$params = @{
    FilePath     = $Context.GetAttachedBinary()
    ArgumentList = "/install /passive /norestart"
    Wait         = $true
    NoNewWindow  = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
$Context.Log("Install complete. Return code: $($result.ExitCode)")
