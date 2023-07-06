#description: Installs Cisco WebEx VDI client with automatic updates disabled. URL to the installer is hard coded in this script.
#execution mode: Combined
#tags: Evergreen, Cisco, WebEx
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Cisco\WebEx"

# https://www.webex.com/downloads/teams-vdi.html
# https://www.cisco.com/c/en/us/td/docs/voice_ip_comm/cloudCollaboration/wbxt/vdi/wbx-vdi-deployment-guide/wbx-teams-vdi-deployment_chapter_010.html

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    $App = [PSCustomObject]@{
        Version = "42.12.0.24485"
        URI = "https://binaries.webex.com/vdi-hvd-aws-gold/20221208010500/Webex.msi"
    }
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}

try {
    Write-Information -MessageData ":: Install Cisco WebEx" -InformationAction "Continue"
    $LogFile = "$Env:ProgramData\Nerdio\Logs\CiscoWebEx$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($OutFile.FullName)`" ENABLEVDI=2 AUTOUPGRADEENABLED=0 ROAMINGENABLED=1 ALLUSERS=1 /quiet /log $LogFile"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
}
catch {
    throw $_.Exception.Message
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
