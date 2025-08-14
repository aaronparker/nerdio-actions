$Context.Log("Installing draw.io")
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package $($Context.GetAttachedBinary()) /quiet /norestart ALLUSERS=1"
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
Start-Process @params

# Post install configuration
$Shortcuts = @("$Env:Public\Desktop\draw.io.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
