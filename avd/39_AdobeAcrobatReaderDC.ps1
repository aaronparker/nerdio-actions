#description: Installs the latest Adobe Acrobat Reader MUI 64-bit with automatic updates disabled
#execution mode: Combined
#tags: Evergreen, Adobe, PDF
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Adobe\AcrobatReaderDC"
[System.String] $Architecture = "x64"
[System.String] $Language = "MUI"

#region Script logic
# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Run tasks/install apps
# Enforce settings with GPO: https://www.adobe.com/devnet-docs/acrobatetk/tools/AdminGuide/gpo.html

try {
    # Download Reader installer
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "AdobeAcrobatReaderDC" | Where-Object { $_.Language -eq $Language -and $_.Architecture -eq $Architecture } | `
        Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    # Install Adobe Acrobat Reader
    $ArgumentList = "-sfx_nu /sALL /rps /l /msi EULA_ACCEPT=YES ENABLE_CHROMEEXT=0 DISABLE_BROWSER_INTEGRATION=1 ENABLE_OPTIMIZATION=YES ADD_THUMBNAILPREVIEW=0 DISABLEDESKTOPSHORTCUT=1 /log `"$env:ProgramData\NerdioManager\Logs\AdobeAcrobatReaderDC.log`""
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = $ArgumentList
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $false
    }
    $result = Start-Process @params
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}

# Disable update tasks - assuming we're installing on a gold image or updates will be managed
try {
    Get-Service -Name "AdobeARMservice" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
    Get-ScheduledTask "Adobe Acrobat Update Task*" | Unregister-ScheduledTask -Confirm:$false -ErrorAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}
#endregion
