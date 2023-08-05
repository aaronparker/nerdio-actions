#description: Installs the latest Microsoft OneDrive per-machine for use on Windows 10/11 multi-session or Windows Server
#execution mode: Combined
#tags: Evergreen, Microsoft, OneDrive, per-machine
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\OneDrive"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    # Run tasks/install apps
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "MicrosoftOneDrive" | `
        Where-Object { $_.Ring -eq "Production" -and $_.Type -eq "exe" -and $_.Architecture -eq "AMD64" } | `
        Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}

try {
    # Install
    Write-Information -MessageData ":: Install Microsoft OneDrive" -InformationAction "Continue"
    reg add "HKLM\Software\Microsoft\OneDrive" /v "AllUsersInstall" /t REG_DWORD /d 1 /reg:64
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = "/silent /allusers"
        NoNewWindow  = $true
        Wait         = $false
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    do {
        Start-Sleep -Seconds 5
    } while (Get-Process -Name "OneDriveSetup" -ErrorAction "SilentlyContinue")
    Get-Process -Name "OneDrive" -ErrorAction "SilentlyContinue" | Stop-Process -Force -ErrorAction "SilentlyContinue"
    Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
}
catch {
    throw $_.Exception.Message
}
#endregion
