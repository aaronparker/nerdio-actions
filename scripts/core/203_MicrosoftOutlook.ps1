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

# Resolve the latest Outlook setup.exe installer
$httpWebRequest = [System.Net.WebRequest]::Create("https://go.microsoft.com/fwlink/?linkid=2207851")
$httpWebRequest.MaximumAutomaticRedirections = 1
$httpWebRequest.AllowAutoRedirect = $true
$httpWebRequest.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.3124.85"
$httpWebRequest.UseDefaultCredentials = $true
$webResponse = $httpWebRequest.GetResponse()
$Uri = $webResponse.ResponseUri.AbsoluteUri
$webResponse.Close()

# Download the Outlook bootstrapper
$App = [PSCustomObject]@{
    Version = "2.0"
    URI     = $Uri
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
