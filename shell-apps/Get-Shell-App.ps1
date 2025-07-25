# Get existing Shell Apps
$params = @{
    Uri             = "https://$NmeHost/api/v1/shell-app"
    Headers         = @{
        "Accept"        = "application/json; utf-8"
        "Authorization" = "Bearer $($Token.access_token)"
        "Content-Type"  = "application/x-www-form-urlencoded"
        "Cache-Control" = "no-cache"
    }
    Method          = "GET"
    UseBasicParsing = $true
}
$ShellApps = Invoke-RestMethod @params
$VsCode = $ShellApps.items | Where-Object { $_.name -eq "Visual Studio Code" }


# Get versions of existing Shell App
$params = @{
    Uri             = "https://$NmeHost/api/v1/shell-app/$($VsCode.id)/version"
    Headers         = @{
        "Accept"        = "application/json; utf-8"
        "Authorization" = "Bearer $($Token.access_token)"
        "Content-Type"  = "application/x-www-form-urlencoded"
        "Cache-Control" = "no-cache"
    }
    Method          = "GET"
    UseBasicParsing = $true
}
$VsCodeVersions = Invoke-RestMethod @params