#description: Downloads the Remote Display Analyzer to 'C:\Program Files\RemoteDisplayAnalyzer'
#execution mode: Combined
#tags: Evergreen, Remote Display Analyzer, Tools
#Requires -Modules Evergreen
[System.String] $Path = "$Env:ProgramFiles\RemoteDisplayAnalyzer"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "RDAnalyzer" | Select-Object -First 1
    Save-EvergreenApp -InputObject $App -CustomPath $Path -Force -WarningAction "SilentlyContinue" | Out-Null
}
catch {
    throw $_
}
#endregion
