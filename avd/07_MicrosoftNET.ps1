#description: Installs the Microsoft .NET Desktop Runtime
#execution mode: Combined
#tags: Evergreen, .NET
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\NET"

#region Script logic
# Create target folder
try {
    New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

    # Download
    $App = Get-EvergreenApp -Name "Microsoft.NET" | Where-Object { $_.Installer -eq "windowsdesktop" -and $_.Architecture -eq "x64" -and $_.Channel -eq "LTS" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = "/install /quiet /norestart /log `"$env:ProgramData\NerdioManager\Logs\Microsoft.NET.log`""
        NoNewWindow  = $True
        PassThru     = $True
        Wait         = $True
    }
    Start-Process @params
}
catch {
    throw $_.Exception.Message
}
#endregion
