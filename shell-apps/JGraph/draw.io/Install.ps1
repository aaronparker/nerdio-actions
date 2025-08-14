$Context.Log("Installing draw.io")
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

# Post install configuration
$Shortcuts = @("$Env:Public\Desktop\draw.io.lnk")
Get-Item -Path $Shortcuts | `
    ForEach-Object { $Context.Log("Remove file: $($_.FullName)"); Remove-Item -Path $_.FullName -Force -ErrorAction "SilentlyContinue" }
