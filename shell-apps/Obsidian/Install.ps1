$params = @{
    FilePath     = $Context.GetAttachedBinary()
    ArgumentList = "/S /ALLUSERS=1 /D=`"${Env:ProgramFiles}\Obsidian`""
    Wait         = $true
    PassThru     = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
$Context.Log("Install complete. Return code: $($result.ExitCode)")
$Context.Log("Install complete")

# Delete public desktop shortcut
$Shortcuts = @("$Env:Public\Desktop\Obsidian.lnk")
Get-Item -Path $Shortcuts -ErrorAction "SilentlyContinue" | `
    ForEach-Object { $Context.Log("Remove file: $($_.FullName)"); Remove-Item -Path $_.FullName -Force -ErrorAction "SilentlyContinue" }
