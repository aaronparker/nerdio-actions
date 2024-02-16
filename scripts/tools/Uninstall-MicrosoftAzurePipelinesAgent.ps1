#description: Uninstalls the Microsoft Azure Pipelines agent.
#execution mode: Combined
#tags: Evergreen, Testing, DevOps
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\agents"

#region Script logic
Push-Location -Path $Path
$params = @{
    FilePath     = "$Path\config.cmd"
    ArgumentList = "remove --unattended --auth pat --token `"$($SecureVars.DevOpsPat)`""
    Wait         = $true
    NoNewWindow  = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params

# Remove the C:\agents directory and the local user account used by the agent service
Remove-Item -Path $Path -Recurse -Force -ErrorAction "SilentlyContinue"
Remove-LocalUser -Name $SecureVars.DevOpsUser -Confirm:$false -ErrorAction "SilentlyContinue"
#endregion
