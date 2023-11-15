#description: Downloads and installs a Microsoft AppLocker policy
#execution mode: Combined
#tags: AppLocker

#region Script logic
[System.String] $Path = "$Env:SystemDrive\Apps\AppLocker"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

if ([System.String]::IsNullOrEmpty($SecureVars.AppLockerPolicyFile)) {
    Write-Host "AppLocker configuration file URL not set."
}
else {
    try {
        #Download the AppLocker configuration
        $OutFile = "$Path\AppLocker$(Get-Date -Format "yyyyMMdd").xml"
        $params = @{
            URI             = $SecureVars.AppLockerPolicyFile
            OutFile         = $OutFile
            UseBasicParsing = $true
            ErrorAction     = "Stop"
        }
        Invoke-WebRequest @params

        # Start the Application Identity service
        Start-Service -Name "AppIDSvc" -ErrorAction "SilentlyContinue"
        sc.exe config appidsvc start= auto

        # Import the AppLocker configuration
        $params = @{
            XmlPolicy   = $OutFile
            ErrorAction = "Stop"
        }
        Set-AppLockerPolicy @params
    }
    catch {
        throw $_
    }
}
#endregion
