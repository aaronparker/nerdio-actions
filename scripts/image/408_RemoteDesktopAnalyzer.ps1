#description: Downloads the Remote Display Analyzer and Connection Experience Indicator to 'C:\Program Files\RemoteDisplayAnalyzer'
#execution mode: Combined
#tags: Evergreen, Remote Display Analyzer, Tools
#Requires -Modules Evergreen
[System.String] $Path = "$Env:ProgramFiles\RemoteDisplayAnalyzer"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force

    Write-Information -MessageData ":: Download Remote Desktop Analyzer" -InformationAction "Continue"
    $App = Get-EvergreenApp -Name "RDAnalyzer" | Select-Object -First 1
    Save-EvergreenApp -InputObject $App -CustomPath $Path -Force -WarningAction "SilentlyContinue" | Out-Null

    Write-Information -MessageData ":: Download Connection Experience Indicator" -InformationAction "Continue"
    $App = Get-EvergreenApp -Name "ConnectionExperienceIndicator" | Select-Object -First 1
    Save-EvergreenApp -InputObject $App -CustomPath $Path -Force -WarningAction "SilentlyContinue" | Out-Null
}
catch {
    throw $_.Exception.Message
}
#endregion
