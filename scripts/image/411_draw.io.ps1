#description: Installs the latest version of draw.io
#execution mode: Combined
#tags: Evergreen, draw.io
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\draw.io"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "diagrams.net" | Where-Object { $_.Type -eq "msi" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}

try {
    Write-Information -MessageData ":: Install draw.io" -InformationAction "Continue"
    $LogFile = "$Env:ProgramData\Nerdio\Logs\diagrams.net$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($OutFile.FullName)`" ALLUSERS=1 /quiet /log $LogFile"
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
$Shortcuts = @("$Env:Public\Desktop\draw.io.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
