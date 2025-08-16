$Context.Log("Installing package: $($Context.GetAttachedBinary())")
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package $($Context.GetAttachedBinary()) /quiet /norestart ALLUSERS=1"
    Wait         = $true
    PassThru     = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
$Context.Log("Install complete. Return code: $($result.ExitCode)")
