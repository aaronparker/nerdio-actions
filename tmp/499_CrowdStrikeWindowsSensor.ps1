#description: Downloads and installs the CrowdStrike Windows Sensor from a specified URL. Run Scripted actions when host VM is STARTED. 
#execution mode: Combined
#tags: CrowdStrike
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\CrowdStrike"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

#region Read variables list
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $params = @{
        Uri             = $SecureVars.VariablesList
        UseBasicParsing = $true
        ErrorAction     = "Stop"
    }
    $Variables = Invoke-RestMethod @params
    [System.String] $CrowdStrikeAgentUrl = $Variables.$AzureRegionName.CrowdStrikeAgent
}
catch {
    throw $_
}
#endregion

try {
    # Download CrowdStrike Windows Sensor, specify a secure variable named CrowdStrikeAgentUrl to pass a custom URL
    $App = [PSCustomObject]@{
        Version = "6.54.16808"
        URI     = $CrowdStrikeAgentUrl
    }
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    # Install the agent
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = "/install /quiet /norestart /log `"$Env:ProgramData\Nerdio\Logs\CrowdStrikeWindowsSensor.log`" CID=$($SecureVars.CrowdStrikeCID) VDI=1" # NO_START=1
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Stop"
    }
    Start-Process @params
}
catch {
    throw $_
}
