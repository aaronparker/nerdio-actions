#description: Installs the latest Microsoft PowerShell
#execution mode: IndividualWithRestart
#tags: Image, Restart

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"
Write-LogFile -Message "Restarting machine."
