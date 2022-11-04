#description: Installs the latest Microsoft Azure Virtual Desktop agents
#execution mode: Combined
#tags: Evergreen, AVD
[System.String] $Path = "$env:SystemDrive\App\Microsoft\Wvd"

#region Script logic
# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

# Run tasks/install apps
#region RTC service
Write-Verbose -Message "Microsoft WvdAgents."
$App = Get-EvergreenApp -Name "MicrosoftWvdRtcService" | Where-Object { $_.Architecture -eq "x64" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $CustomPath -WarningAction "SilentlyContinue"

# Install RTC
Write-Verbose -Message "Installing Microsoft Remote Desktop WebRTC Redirector Service: $($App.Version)."
$params = @{
    FilePath     = "$env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package $($OutFile.FullName) ALLUSERS=1 /quiet /Log $LogPath"
    NoNewWindow  = $True
    Wait         = $True
    PassThru     = $True
}
$result = Start-Process @params
$Output = [PSCustomObject] @{
    Path     = $OutFile.FullName
    ExitCode = $result.ExitCode
}
Write-Verbose -Message -InputObject $Output
#endregion

#region Boot Loader
Write-Verbose -Message "Microsoft Windows Virtual Desktop Agent Bootloader"
$App = Get-EvergreenApp -Name "MicrosoftWvdBootLoader" | Where-Object { $_.Architecture -eq "x64" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -Path $CustomPath -WarningAction "SilentlyContinue"

# Install
Write-Verbose -Message "Installing Microsoft Windows Virtual Desktop Agent Bootloader: $($App.Version)."
$params = @{
    FilePath     = "$env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package $($OutFile.FullName) ALLUSERS=1 /quiet /Log $LogPath"
    NoNewWindow  = $True
    Wait         = $True
    PassThru     = $True
}
$result = Start-Process @params
$Output = [PSCustomObject] @{
    Path     = $OutFile.FullName
    ExitCode = $result.ExitCode
}
Write-Verbose -Message -InputObject $Output
#endregion

#region Infra agent
<#
Write-Verbose -Message "Microsoft WVD Infrastructure Agent"
$App = Get-EvergreenApp -Name "MicrosoftWvdInfraAgent" | Where-Object { $_.Architecture -eq "x64" }
$OutFile = Save-EvergreenApp -InputObject $App -Path $CustomPath -WarningAction "SilentlyContinue"
Write-Verbose -Message "Installing Microsoft WVD Infrastructure Agent"
$params = @{
    FilePath     = "$env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package $($OutFile.FullName) ALLUSERS=1 /quiet"
    NoNewWindow  = $True
    Wait         = $True
    PassThru     = $True
}
$result = Start-Process @params
$Output = [PSCustomObject] @{
    Path     = $OutFile.FullName
    ExitCode = $result.ExitCode
}
Write-Verbose -Message -InputObject $Output
#>
#endregion
