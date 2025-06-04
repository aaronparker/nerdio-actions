# Warning - uninstalling Microsoft Edge is probably not a good idea, but this is how you do it.

# Uninstall Microsoft Edge using the setup.exe in the Edge application directory
$SetupExe = Get-ChildItem -Path "${Env:ProgramFiles(x86)}\Microsoft\Edge\Application" -Recurse -Include "setup.exe" | `
    Select-Object -First 1

$params = @{
    FilePath     = $SetupExe.FullName
    ArgumentList = "setup.exe --uninstall --system-level --verbose-logging --force-uninstall"
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
Start-Process @params
$Context.Log("Uninstall complete")
