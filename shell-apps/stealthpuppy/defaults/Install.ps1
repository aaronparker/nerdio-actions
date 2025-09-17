# Configure the environment
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$InformationPreference = [System.Management.Automation.ActionPreference]::Continue
$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

# Unzip and run all Install-Defaults.ps1 scripts
Expand-Archive -Path $Context.GetAttachedBinary() -DestinationPath $PWD -Force
Get-ChildItem -Path $PWD -Include "Install-Defaults.ps1" -Recurse -File | ForEach-Object {
    $Context.Log("Executing: $($_.FullName)")
    & $_.FullName
}
$Context.Log("Install complete")
