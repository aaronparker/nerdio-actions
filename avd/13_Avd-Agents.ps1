#description: Installs the latest Microsoft Azure Virtual Desktop agents
#execution mode: Combined
#tags: Evergreen, AVD
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\Avd"

#region Script logic
# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Run tasks/install apps
#region Microsoft Remote Desktop WebRTC Redirector Service
try {
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "MicrosoftWvdRtcService" | Where-Object { $_.Architecture -eq "x64" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

    # Install RTC
    $params = @{
        FilePath     = "$env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($OutFile.FullName)`" /quiet /log `"$env:ProgramData\NerdioManager\Logs\MicrosoftWvdRtcService.log`""
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $false
    }
    $result = Start-Process @params
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}
#endregion

#region Microsoft Azure Virtual Desktop Multimedia Redirection Extensions
try {
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "MicrosoftWvdMultimediaRedirection" | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

    # Install MMR
    $params = @{
        FilePath     = "$env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($OutFile.FullName)`" /quiet /log `"$env:ProgramData\NerdioManager\Logs\MicrosoftWvdMultimediaRedirection.log`""
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $false
    }
    $result = Start-Process @params
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}
#endregion


# The items below should be installed automatically
#region Boot Loader
<#
try {
$App = Get-EvergreenApp -Name "MicrosoftWvdBootLoader" | Where-Object { $_.Architecture -eq "x64" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

# Install
$params = @{
    FilePath     = "$env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package `"$($OutFile.FullName)`" /quiet `"$env:ProgramData\NerdioManager\Logs\MicrosoftWvdBootLoader.log`""
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $false
}
$params
Start-Process @params
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}
#>
#endregion

#region Infra agent
<#
try {
$App = Get-EvergreenApp -Name "MicrosoftWvdInfraAgent" | Where-Object { $_.Architecture -eq "x64" }
$OutFile = Save-EvergreenApp -InputObject $App -Path $Path -WarningAction "SilentlyContinue"
$params = @{
    FilePath     = "$env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package $($OutFile.FullName) /quiet `"$env:ProgramData\NerdioManager\Logs\MicrosoftWvdInfraAgent.log`""
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $false
}
Start-Process @params
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}
#>
#endregion
