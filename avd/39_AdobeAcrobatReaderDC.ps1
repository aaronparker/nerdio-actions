#description: Installs the latest Adobe Acrobat Reader MUI x64 customised for VDI
#execution mode: Combined
#tags: Evergreen, Adobe
#Requires -Modules Evergreen
<#
    .SYNOPSIS
        Install evergreen core applications.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs progress to the pipeline log")]
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\Apps\Adobe\AcrobatReaderDC",

    [Parameter(Mandatory = $False)]
    [System.String] $Architecture = "x64",

    [Parameter(Mandatory = $False)]
    [System.String] $Language = "MUI"
)

#region Script logic

# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

# Run tasks/install apps
# Enforce settings with GPO: https://www.adobe.com/devnet-docs/acrobatetk/tools/AdminGuide/gpo.html
# Download Reader installer and updater
Write-Host "Adobe Acrobat Reader DC"
$Reader = Get-EvergreenApp -Name "AdobeAcrobatReaderDC" | Where-Object { $_.Language -eq $Language -and $_.Architecture -eq $Architecture } | `
    Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $Reader -CustomPath $Path -WarningAction "SilentlyContinue"

# Install Adobe Acrobat Reader
Write-Host "Installing Adobe Acrobat Reader DC"
$ArgumentList = "-sfx_nu /sALL /rps /l /msi EULA_ACCEPT=YES ENABLE_CHROMEEXT=0 DISABLE_BROWSER_INTEGRATION=1 ENABLE_OPTIMIZATION=YES ADD_THUMBNAILPREVIEW=0 DISABLEDESKTOPSHORTCUT=1"
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = $ArgumentList
    NoNewWindow  = $True
    Wait         = $True
    PassThru     = $True
}
$result = Start-Process @params
$Output = [PSCustomObject] @{
    Path     = $OutFile.FullName
    ExitCode = $result.ExitCode
}
Write-Host -InputObject $Output

# Configure update tasks
Write-Host "Configure Adobe Acrobat Reader services"
try {
    Get-Service -Name "AdobeARMservice" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
    Get-ScheduledTask "Adobe Acrobat Update Task*" | Unregister-ScheduledTask -Confirm:$False -ErrorAction "SilentlyContinue"
}
catch {
    Write-Warning -Message "`tERR: $($_.Exception.Message)."
}

Write-Host "Complete: Adobe Acrobat Reader DC."
#endregion
