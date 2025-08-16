$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($Context.GetAttachedBinary())`" /quiet"
    Wait         = $true
    NoNewWindow  = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
$Context.Log("Install complete. Return code: $($result.ExitCode)")
