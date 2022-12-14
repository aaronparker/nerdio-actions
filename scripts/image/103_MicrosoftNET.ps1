#description: Installs the Microsoft .NET Desktop LTS and Current Runtimes
#execution mode: Combined
#tags: Evergreen, Microsoft, .NET
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\NET"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

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

foreach ($file in $OutFile) {
    try {
        $LogFile = "$Env:ProgramData\Evergreen\Logs\Microsoft.NET.log" -replace " ", ""
        $params = @{
            FilePath     = $file.FullName
            ArgumentList = "/install /quiet /norestart /log $LogFile"
            NoNewWindow  = $true
            PassThru     = $true
            Wait         = $true
            ErrorAction  = "Continue"
        }
        $result = Start-Process @params
        $result.ExitCode
    }
    catch {
        throw $_
    }
}
#endregion
