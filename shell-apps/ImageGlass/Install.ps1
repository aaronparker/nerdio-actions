$Context.Log("Installing ImageGlass")
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($Context.GetAttachedBinary())`" RUNAPPLICATION=0 ALLUSERS=1 ALLUSERS=1 /quiet"
    Wait         = $true
    PassThru     = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
$Context.Log("Install complete. Return code: $($result.ExitCode)")

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:Public\Desktop\ImageGlass.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\ImageGlass\ImageGlass' LICENSE.lnk",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\ImageGlass\Uninstall ImageGlass*.lnk")
Get-Item -Path $Shortcuts -ErrorAction "SilentlyContinue" | `
    ForEach-Object { $Context.Log("Remove file: $($_.FullName)"); Remove-Item -Path $_.FullName -Force -ErrorAction "SilentlyContinue" }
