#description: Installs the latest Adobe Acrobat Reader MUI x64 customised for VDI
#execution mode: Combined
#tags: Evergreen, Adobe
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Adobe\AcrobatReaderDC"

[System.String] $Architecture = "x64"

[System.String] $Language = "MUI"

#region Script logic
# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

# Run tasks/install apps
# Enforce settings with GPO: https://www.adobe.com/devnet-docs/acrobatetk/tools/AdminGuide/gpo.html

try {
    # Download Reader installer and updater
    $Reader = Get-EvergreenApp -Name "AdobeAcrobatReaderDC" | Where-Object { $_.Language -eq $Language -and $_.Architecture -eq $Architecture } | `
        Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $Reader -CustomPath $Path -WarningAction "SilentlyContinue"

    # Install Adobe Acrobat Reader
    $ArgumentList = "-sfx_nu /sALL /rps /l /msi EULA_ACCEPT=YES ENABLE_CHROMEEXT=0 DISABLE_BROWSER_INTEGRATION=1 ENABLE_OPTIMIZATION=YES ADD_THUMBNAILPREVIEW=0 DISABLEDESKTOPSHORTCUT=1"
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = $ArgumentList
        NoNewWindow  = $True
        Wait         = $True
        PassThru     = $False
    }
    $result = Start-Process @params
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}

# Configure update tasks
try {
    Get-Service -Name "AdobeARMservice" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
    Get-ScheduledTask "Adobe Acrobat Update Task*" | Unregister-ScheduledTask -Confirm:$False -ErrorAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}
#endregion
