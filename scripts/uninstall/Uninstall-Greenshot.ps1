#description: Uninstalls Greenshot
#execution mode: Combined
#tags: Uninstall, Greenshot

#region Script logic
try {
    Get-Process -ErrorAction "SilentlyContinue" | `
        Where-Object { $_.Path -like "$Env:ProgramFiles\Greenshot\*" } | `
        Stop-Process -Force -ErrorAction "SilentlyContinue"
}
catch {
    Write-Warning -Message "Failed to stop Greenshot processes."
}

if (Test-Path -Path "$Env:ProgramFiles\Greenshot\unins000.exe") {
    $params = @{
        FilePath     = "$Env:ProgramFiles\Greenshot\unins000.exe"
        ArgumentList = "/VERYSILENT"
        NoNewWindow  = $true
        PassThru     = $true
        Wait         = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    $result.ExitCode
    if ($result.ExitCode -eq 0) {
        if (Test-Path -Path "$Env:ProgramFiles\Greenshot") {
            Remove-Item -Path "$Env:ProgramFiles\Greenshot" -Recurse -Force -ErrorAction "SilentlyContinue"
        }
    }
}
#endregion
