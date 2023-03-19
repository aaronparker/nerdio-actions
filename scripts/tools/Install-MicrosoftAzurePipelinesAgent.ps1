#description: Installs the Microsoft Azure Pipelines agent to enable automated testing via Azure Pipelines. Do not run on production session hosts.
#execution mode: Combined
#tags: Evergreen, Testing, DevOps
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\agents"

# Check that the required variables have been set in Nerdio Manager
foreach ($Value in "DevOpsUrl", "DevOpsPat", "DevOpsPool") {
    if ($null -eq $SecureVars.$Value) { throw "$Value is $null" }
}

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    # Download
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "MicrosoftAzurePipelinesAgent" | `
        Where-Object { $_.Architecture -eq "x64" } | `
        Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Env:Temp -WarningAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}

try {
    Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force
    Push-Location -Path $Path
    $params = @{
        FilePath     = "$Path\config.cmd"
        ArgumentList = "--unattended --url $($SecureVars.DevOpsUrl) --auth pat --token `"$($SecureVars.DevOpsPat)`" --pool `"$($SecureVars.DevOpsPool)`" --agent $Env:COMPUTERNAME --runAsService --replace"
        Wait         = $true
        WindowStyle  = "hidden"
    }
    $result = Start-Process @params
    Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
}
catch {
    throw $_
}
#endregion
