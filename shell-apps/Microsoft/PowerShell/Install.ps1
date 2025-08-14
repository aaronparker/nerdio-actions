$Context.Log("Installing Microsoft PowerShell")
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package $($Context.GetAttachedBinary()) /quiet /norestart"
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
Start-Process @params
$Context.Log("Install complete")
