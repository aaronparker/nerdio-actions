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

try {
    $params = @{
        FilePath     = "$env:ProgramFiles\Greenshot\unins000.exe"
        ArgumentList = "/VERYSILENT"
        NoNewWindow  = $True
        PassThru     = $True
        Wait         = $True
    }
    $result = Start-Process @params
    if ($result.ExitCode -eq 0) {
        Remove-Item -Path "$env:ProgramFiles\Greenshot" -Recurse -Force -ErrorAction "SilentlyContinue"
    }
}
catch {
    throw $_
}
finally {
    exit $result.ExitCode
}
#endregion
