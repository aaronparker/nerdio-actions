$Context.Log("Installing Microsoft Azure CLI")
$params = @{
    FilePath     = $Context.GetAttachedBinary()
    ArgumentList = "/install /quiet /norestart ALLUSERS=1"
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
Start-Process @params
$Context.Log("Install complete")
