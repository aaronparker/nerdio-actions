#description: Installs the Microsoft .NET Desktop Runtime
#execution mode: Combined
#tags: Evergreen, .NET
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\NET"

#region Script logic
# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    # Download
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "Microsoft.NET" | Where-Object { $_.Installer -eq "windowsdesktop" -and $_.Architecture -eq "x64" -and $_.Channel -match "LTS|Current" }
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
    foreach ($file in $OutFile) {
        $params = @{
            FilePath     = $file.FullName
            ArgumentList = "/install /quiet /norestart /log `"$env:ProgramData\NerdioManager\Logs\Microsoft.NET.log`""
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
