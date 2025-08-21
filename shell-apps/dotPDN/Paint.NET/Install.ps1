Get-ChildItem -Path $PWD -Recurse -Include "paint.*msi" | ForEach-Object {
    $Context.Log("Installing Paint.NET from: $($_.FullName)")
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($_.FullName)`" DESKTOPSHORTCUT=0 CHECKFORUPDATES=0 CHECKFORBETAS=0 /quiet"
        Wait         = $true
        NoNewWindow  = $true
        PassThru     = $true
        ErrorAction  = "Stop"
    }
    $result = Start-Process @params
    $Context.Log("Install complete. Return code: $($result.ExitCode)")
}

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:Public\Desktop\Paint.NET.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
