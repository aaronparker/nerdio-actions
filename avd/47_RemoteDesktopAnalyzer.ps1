#description: Downloads the Remote Display Analyzer to 'C:\Program Files\RemoteDisplayAnalyzer'
#execution mode: Combined
#tags: Evergreen, Remote Display Analyzer
#Requires -Modules Evergreen
[System.String] $Path = "$env:ProgramFiles\RemoteDisplayAnalyzer"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$env:ProgramData\NerdioManager\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "RDAnalyzer" | Select-Object -First 1
    Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue" | Out-Null
}
catch {
    throw $_
}
#endregion
