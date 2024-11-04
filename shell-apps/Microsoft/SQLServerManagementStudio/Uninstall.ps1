$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/uninstall `"{98FA3A6A-2028-4F6B-993E-D1851F0D5EC6}`" /quiet /norestart"
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
Start-Process @params
