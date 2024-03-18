#description: Downloads and installs the Synapse MSI from a specified URL
#tags: Synapse
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Synapse"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $params = @{
        Uri             = $SecureVars.VariablesList
        UseBasicParsing = $true
        ErrorAction     = "Stop"
    }
    $Variables = Invoke-RestMethod @params
    $App = [PSCustomObject]@{
        Version = "4.4.400"
        URI     = $Variables.$AzureRegionName.Synapse
    }
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    # Install the agent
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$OutFile.FullName`" /quiet /norestart /log `"$Env:ProgramData\Nerdio\Logs\Synapse.log`" ENABLE_UPDATE_NOTIFICATION=0 ISCHECKFORPRODUCTUPDATES=0"
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
