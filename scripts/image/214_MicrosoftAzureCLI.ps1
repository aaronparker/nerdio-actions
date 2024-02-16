#description: Installs the latest Microsoft Azure CLI
#execution mode: Combined
#tags: Evergreen, Microsoft, Azure
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\AzureCli"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "MicrosoftAzureCLI" | `
    Where-Object { $_.Type -eq "msi" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

Write-Information -MessageData ":: Install Microsoft Azure CLI" -InformationAction "Continue"
$LogFile = "$Env:ProgramData\Nerdio\Logs\MicrosoftAvdCli$($App.Version).log" -replace " ", ""
$params = @{
    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" /quiet /norestart ALLUSERS=1 /log $LogFile"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Continue"
}
$result = Start-Process @params
Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
#endregion
