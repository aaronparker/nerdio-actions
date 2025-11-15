#description: Installs the new Microsoft Outlook app
#execution mode: Combined
#tags: Evergreen, Microsoft, Outlook, per-machine
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Outlook"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

$App = [PSCustomObject]@{
    Version = "2.0.0"
    URI     = "https://res.cdn.office.net/nativehost/5mttl/installer/v2/indirect/Setup.exe"
}
$OutlookExe = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"
Write-LogFile -Message "Downloaded Microsoft Outlook to: $($OutlookExe.FullName)"

Write-LogFile -Message "Installing Microsoft Outlook"
$params = @{
    FilePath     = $OutlookExe.FullName
    ArgumentList = "--provision true --quiet --start-"
}
Start-ProcessWithLog @params
