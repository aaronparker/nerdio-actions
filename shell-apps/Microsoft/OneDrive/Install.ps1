$Context.Log("Run: 'reg add HKLM\Software\Microsoft\OneDrive /v AllUsersInstall /t REG_DWORD /d 1 /reg:64 /f'")
reg add "HKLM\Software\Microsoft\OneDrive" /v "AllUsersInstall" /t REG_DWORD /d 1 /reg:64 /f *> $null
$params = @{
    FilePath     = $Context.GetAttachedBinary()
    ArgumentList = "/silent /allusers"
    Wait         = $false
    PassThru     = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
do {
    $Context.Log("Waiting for OneDrive Setup to complete.")
    Start-Sleep -Seconds 5
} while (Get-Process -Name "OneDriveSetup" -ErrorAction "SilentlyContinue")
$Context.Log("OneDrive Setup completed.")
$Context.Log("Wait a further 10 seconds for processes to complete")
Start-Sleep -Seconds 10
Get-Process -Name "OneDrive" -ErrorAction "SilentlyContinue" | ForEach-Object {
    $Context.Log("Stopped OneDrive process: $($_.Name)")
    Stop-Process -Name $_.Name -Force -ErrorAction "SilentlyContinue"
}
$Context.Log("Install complete. Return code: $($result.ExitCode)")
