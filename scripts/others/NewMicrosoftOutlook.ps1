# Outlook
$params = @{
    FilePath     = "C:\Users\Aaron\Downloads\Setup.exe"
    ArgumentList = "--provision true --quiet --logfile=D:\projects\Outlook.log --start false"
    Wait         = $true
    NoNewWindow  = $true
}
Start-Process @params
