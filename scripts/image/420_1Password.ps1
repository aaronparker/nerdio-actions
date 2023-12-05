#description: Installs the 1Password Windows client
#execution mode: Combined
#tags: Evergreen, AgileBits, 1Password
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\AgileBits\1Password"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    # Download
    $App = [PSCustomObject]@{
        Version = "8.10.18"
        URI     = "https://downloads.1password.com/win/1PasswordSetup-latest.msi"
    }
    Import-Module -Name "Evergreen" -Force
    #$App = Get-EvergreenApp -Name "1Password" | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "Stop"
}
catch {
    throw $_
}

Write-Information -MessageData ":: Install AgileBits 1Password" -InformationAction "Continue"
try {
    # Install package
    $LogFile = "$Env:ProgramData\Nerdio\Logs\1Password.log" -replace " ", ""
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($OutFile.FullName)`" /quiet /log $LogFile"
        NoNewWindow  = $true
        PassThru     = $true
        Wait         = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
}
catch {
    throw $_
}
#endregion