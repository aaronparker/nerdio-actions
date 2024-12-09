<#
    .SYNOPSIS
    Installs the latest Microsoft Outlook app.

    .DESCRIPTION
    This script installs the latest version of Microsoft Outlook by downloading the bootstrapper and executing the installer. 
    It ensures the installation directory exists, downloads the Outlook installer, and runs it with specific parameters. 
    After installation, it stops the Outlook process if it is running.

    .PARAMETER Path
    Specifies the directory where the Outlook app will be installed.

    .NOTES
    Requires the Evergreen module to be installed.
#>

#description: Installs the latest Microsoft Outlook app
#execution mode: Combined
#tags: Evergreen, Microsoft, Outlook
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\Outlook"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Download the Outlook bootstrapper
$App = [PSCustomObject]@{
    Version = "1.2024.02.100"
    URI     = "https://res.cdn.office.net/nativehost/5mttl/installer/v2/prod/Setup.exe"
}
$OutlookExe = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

# Install Outlook
$params = @{
    FilePath     = $OutlookExe.FullName
    ArgumentList = "--provision true --quiet --logfile=$Env:SystemRoot\Logs\ImageBuild\MicrosoftOutlook.log --verbose"
    Wait         = $true
}
Start-Process @params

# Stop the Outlook process - Outlook runs after install
Stop-Process -Name "Olk" -Force -ErrorAction "SilentlyContinue"
