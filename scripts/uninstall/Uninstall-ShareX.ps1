#description: Uninstalls ShareX
#execution mode: Combined
#tags: Uninstall, ShareX

#region Script logic
try {
    Get-Process -ErrorAction "SilentlyContinue" | `
        Where-Object { $_.Path -like "$Env:ProgramFiles\ShareX\*" } | `
        Stop-Process -Force -ErrorAction "SilentlyContinue"
}
catch {
    Write-Warning -Message "Failed to stop ShareX processes."
}

if (Test-Path -Path "$Env:ProgramFiles\ShareX\unins000.exe") {
    $params = @{
        FilePath     = "$Env:ProgramFiles\ShareX\unins000.exe"
        ArgumentList = "/VERYSILENT"
        NoNewWindow  = $true
        PassThru     = $true
        Wait         = $true
        ErrorAction  = "Stop"
    }
    $result = Start-Process @params
    if ($result.ExitCode -eq 0) {
        if (Test-Path -Path "$Env:ProgramFiles\ShareX") {
            Remove-Item -Path "$Env:ProgramFiles\ShareX" -Recurse -Force -ErrorAction "SilentlyContinue"
        }
    }
}
#endregion
