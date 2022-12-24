#description: Installs the Microsoft .NET Desktop LTS and Current Runtimes
#execution mode: Combined
#tags: Evergreen, Microsoft, .NET
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\NET"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    # Download
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "Microsoft.NET" | `
        Where-Object { $_.Installer -eq "windowsdesktop" -and $_.Architecture -eq "x64" -and $_.Channel -match "LTS|Current" }
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    foreach ($file in $OutFile) {
        $LogFile = "$env:ProgramData\Evergreen\Logs\Microsoft.NET.log" -replace " ", ""
        $params = @{
            FilePath     = $file.FullName
            ArgumentList = "/install /quiet /norestart /log $LogFile"
            NoNewWindow  = $true
            PassThru     = $false
            Wait         = $true
        }
        $result = Start-Process @params
    }
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}
#endregion
