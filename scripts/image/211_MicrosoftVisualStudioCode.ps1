#description: Installs the latest Microsoft Visual Studio Code 64-bit
#execution mode: Combined
#tags: Evergreen, Microsoft, Visual Studio Code
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\VisualStudioCode"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "MicrosoftVisualStudioCode" | `
        Where-Object { $_.Architecture -eq "x64" -and $_.Platform -eq "win32-x64" -and $_.Channel -eq "Stable" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}

try {
    Write-Information -MessageData ":: Install Microsoft Visual Studio Code" -InformationAction "Continue"
    $LogFile = "$Env:ProgramData\Nerdio\Logs\MicrosoftVisualStudioCode$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = "/VERYSILENT /NOCLOSEAPPLICATIONS /NORESTARTAPPLICATIONS /NORESTART /SP- /SUPPRESSMSGBOXES /MERGETASKS=!runcode /LOG=$LogFile"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
}
catch {
    throw $_.Exception.Message
}

Start-Sleep -Seconds 5
Get-Process -ErrorAction "SilentlyContinue" | `
    Where-Object { $_.Path -like "$Env:ProgramFiles\Microsoft VS Code\*" } | `
    Stop-Process -Force -ErrorAction "SilentlyContinue"
#endregion
