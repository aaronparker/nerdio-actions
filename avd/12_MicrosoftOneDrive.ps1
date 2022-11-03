#description: Installs the latest Microsoft OneDrive for use on Windows 10/11 multi-session or Windows Server
#execution mode: Combined
#tags: Evergreen, OneDrive
#Requires -Modules Evergreen
<#
    .SYNOPSIS
        Install evergreen core applications.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\Apps\Microsoft\OneDrive"
)

#region Script logic

# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

# Run tasks/install apps
Write-Host "Microsoft OneDrive"
$App = Get-EvergreenApp -Name "MicrosoftOneDrive" | Where-Object { $_.Ring -eq "Production" -and $_.Type -eq "Exe" -and $_.Architecture -eq "AMD64" } | `
    Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

# Install
Write-Host "Installing Microsoft OneDrive: $($App.Version)."
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/silent /ALLUSERS"
    NoNewWindow  = $True
    Wait         = $False
    PassThru     = $True
}
$result = Start-Process @params
do {
    Start-Sleep -Seconds 10
} while (Get-Process -Name "OneDriveSetup" -ErrorAction "SilentlyContinue")
Get-Process -Name "OneDrive" -ErrorAction "SilentlyContinue" | Stop-Process -Force -ErrorAction "SilentlyContinue"
$Output = [PSCustomObject] @{
    Path     = $OutFile.FullName
    ExitCode = $result.ExitCode
}
Write-Host -InputObject $Output

Write-Host "Complete: Microsoft OneDrive."
#endregion
