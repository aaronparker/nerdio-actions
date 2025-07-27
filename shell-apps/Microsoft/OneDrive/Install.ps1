$Context.Log("Installing Microsoft OneDrive")
$params = @{
    FilePath     = $Context.GetAttachedBinary()
    ArgumentList = "/install /quiet /norestart"
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
Start-Process @params
$Context.Log("Install complete")
