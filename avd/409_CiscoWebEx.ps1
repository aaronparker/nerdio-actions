#description: Installs Cisco WebEx VDI client with automatic updates disabled. URL to the installer is hard coded in this script.
#execution mode: Combined
#tags: Evergreen, Cisco, WebEx
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Cisco\WebEx"

# https://www.cisco.com/c/en/us/td/docs/voice_ip_comm/cloudCollaboration/wbxt/vdi/wbx-vdi-deployment-guide/wbx-teams-vdi-deployment_chapter_010.html

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$env:ProgramData\NerdioManager\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    $App = [PSCustomObject]@{
        Version = "42.10.0.23814"
        URI = "https://binaries.webex.com/vdi-hvd-aws-gold/20221008081418/Webex.msi"
    }
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    $params = @{
        FilePath     = "$env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($OutFile.FullName)`" ALLUSERS=1 ENABLEVDI=2 AUTOUPGRADEENABLED=0 ROAMINGENABLED=1 /quiet /log `"$env:ProgramData\NerdioManager\Logs\CiscoWebEx.log`""
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $false
    }
    $result = Start-Process @params
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:Public\Desktop\WebEx.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"

try {
    reg add "HKLM\SOFTWARE\Cisco Spark Native" /v "isVDIEnv" /d "true" /t "REG_EXPAND_SZ" /f | Out-Null
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "CiscoSpark" /f | Out-Null
}
catch {
    throw $_.Exception.Message
}
#endregion
