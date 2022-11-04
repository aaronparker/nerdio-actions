#description: Installs the Microsoft .NET Desktop Runtime
#execution mode: Combined
#tags: Evergreen, .NET
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\NET"

#region Script logic
# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null
Write-Verbose -Message "Microsoft Windows Desktop Runtime"

# Download
$App = Get-EvergreenApp -Name "Microsoft.NET" | Where-Object { $_.Installer -eq "windowsdesktop" -and $_.Architecture -eq "x64" -and $_.Channel -eq "LTS" } | Select-Object -First 1
Write-Verbose -Message "Microsoft Windows Desktop Runtime: $($App.Version)."
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/install /quiet /norestart"
    NoNewWindow  = $True
    PassThru     = $True
    Wait         = $True
}
$result = Start-Process @params
$Output = [PSCustomObject] @{
    Path     = $OutFile.FullName
    ExitCode = $result.ExitCode
}
Write-Verbose -Message -InputObject $Output
#endregion
