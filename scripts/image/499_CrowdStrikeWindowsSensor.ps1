#description: Downloads and installs the CrowdStrike Windows Sensor from a specified URL. Run Scripted actions when host VM is STARTED. 
#execution mode: Combined
#tags: CrowdStrike
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\CrowdStrike"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    # Download CrowdStrike Windows Sensor, specify a secure variable named CrowdStrikeAgentUrl to pass a custom URL
    $App = [PSCustomObject]@{
        Version = "6.54.16808"
        URI     = $SecureVars.CrowdStrikeAgentUrl
    }
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}

try {
    # Install the agent
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = "/install /quiet /norestart /log `"$Env:ProgramData\Nerdio\Logs`" CID=$($SecureVars.CrowdStrikeCID) VDI=1" # NO_START=1
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Stop"
    }
    Start-Process @params
}
catch {
    throw $_.Exception.Message
}
