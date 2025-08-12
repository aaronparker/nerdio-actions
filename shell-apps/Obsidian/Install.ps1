$Context.Log("Installing Obsidian")
$params = @{
    FilePath     = $Context.GetAttachedBinary()
    ArgumentList = "/S /D=`"${Env:ProgramFiles}\Obsidian`""
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
Start-Process @params
$Context.Log("Install complete")

# Delete public desktop shortcut
$Context.Log("Removing public desktop shortcut")
$Shortcuts = @("$Env:Public\Desktop\Obsidian.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "SilentlyContinue"
