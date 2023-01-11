#description: Uninstalls Greenshot
#execution mode: Combined
#tags: Uninstall, Greenshot

#region Script logic
try {
    Get-Process -ErrorAction "SilentlyContinue" | `
        Where-Object { $_.Path -like "$env:ProgramFiles\Greenshot\*" } | `
        Stop-Process -Force -ErrorAction "SilentlyContinue"
}
catch {
    Write-Warning -Message "Failed to stop Greenshot processes."
}

if (Test-Path -Path "$env:ProgramFiles\Greenshot\unins000.exe") {
    $params = @{
        FilePath     = "$env:ProgramFiles\Greenshot\unins000.exe"
        ArgumentList = "/VERYSILENT"
        NoNewWindow  = $True
        PassThru     = $True
        Wait         = $True
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    $result.ExitCode
    if ($result.ExitCode -eq 0) {
        if (Test-Path -Path "$env:ProgramFiles\Greenshot") {
            Remove-Item -Path "$env:ProgramFiles\Greenshot" -Recurse -Force -ErrorAction "SilentlyContinue"
        }
    }
}
#endregion
