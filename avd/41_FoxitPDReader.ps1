#description: Installs the latest Foxit PDF Reader with automatic updates disabled
#execution mode: Combined
#tags: Evergreen, Foxit, PDF
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Foxit\PDFReader"

#region Script logic
# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "FoxitReader" | Where-Object { $_.Language -eq "English" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    $params = @{
        FilePath     = "$env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($OutFile.FullName)`" AUTO_UPDATE=0 NOTINSTALLUPDATE=1 MAKEDEFAULT=0 LAUNCHCHECKDEFAULT=0 VIEW_IN_BROWSER=0 DESKTOP_SHORTCUT=0 STARTMENU_SHORTCUT_UNINSTALL=0 DISABLE_UNINSTALL_SURVEY=1 ALLUSERS=1 /log `"$env:ProgramData\NerdioManager\Logs\FoxitReader.log`""
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $false
    }
    $result = Start-Process @params
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}
#endregion
