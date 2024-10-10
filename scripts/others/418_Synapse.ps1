#description: Downloads and installs the Synapse MSI from a specified URL
#tags: Synapse
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Synapse"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Download Synapse MSI, specify a secure variable named SynapseUrl to pass a custom URL
$App = [PSCustomObject]@{
    Version = "4.4.400"
    URI     = $SecureVars.SynapseUrl
}
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

# Install the agent
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$OutFile.FullName`" /quiet /norestart /log `"$Env:SystemRoot\Logs\ImageBuild\Synapse.log`" ENABLE_UPDATE_NOTIFICATION=0 ISCHECKFORPRODUCTUPDATES=0"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params
