#description: Installs the Microsoft .NET Desktop Runtime
#execution mode: Combined
#tags: Evergreen, .NET
#Requires -Modules Evergreen
<#
    .SYNOPSIS
        Install evergreen core applications.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\Apps\Microsoft\NET"
)


#region Script logic
# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null
Write-Host "Microsoft Windows Desktop Runtime"

# Download
$App = Get-EvergreenApp -Name "Microsoft.NET" | Where-Object { $_.Installer -eq "windowsdesktop" -and $_.Architecture -eq "x64" -and $_.Channel -eq "LTS" } | Select-Object -First 1
Write-Host "Microsoft Windows Desktop Runtime: $($App.Version)."
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
Write-Host -InputObject $Output
#endregion
