#description: Installs the latest version of draw.io
#execution mode: Combined
#tags: Evergreen, draw.io
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\draw.io"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "diagrams.net" | Where-Object { $_.Type -eq "msi" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    $LogFile = "$env:ProgramData\Evergreen\Logs\diagrams.net$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = "$env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($OutFile.FullName)`" ALLUSERS=1 /quiet /log $LogFile"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
    }
    $result = Start-Process @params
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}

Start-Sleep -Seconds 5
$Shortcuts = @("$env:Public\Desktop\draw.io.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
