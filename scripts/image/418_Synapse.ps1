#description: Downloads and installs the Synapse MSI from a specified URL
#tags: Synapse
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Synapse"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    # Download Synapse MSI, specify a secure variable named SynapseUrl to pass a custom URL
    $App = [PSCustomObject]@{
        Version = "4.4.400"
        URI     = $SecureVars.SynapseUrl
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
        ArgumentList = "/install /quiet /norestart /log `"$Env:ProgramData\Nerdio\Logs\Synapse.log`""
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
