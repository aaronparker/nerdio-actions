#description: Installs the latest Microsoft FSLogix Apps agent and the FSLogix Apps Rules Editor
#execution mode: Combined
#tags: Evergreen, Microsoft, FSLogix
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Microsoft\FSLogix"


#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    # Download and unpack
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "MicrosoftFSLogixApps" | Where-Object { $_.Channel -eq "Production" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
    Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force
}
catch {
    throw $_
}

# Install
Write-Information -MessageData ":: Install Microsoft FSLogix agent" -InformationAction "Continue"
foreach ($file in "FSLogixAppsSetup.exe", "FSLogixAppsRuleEditorSetup.exe") {
    $Installers = Get-ChildItem -Path $Path -Recurse -Include $file | Where-Object { $_.Directory -match "x64" }
    foreach ($Installer in $Installers) {
        try {
            $LogFile = "$Env:ProgramData\Evergreen\Logs\$($Installer.Name)$($App.Version).log" -replace " ", ""
            $params = @{
                FilePath     = $Installer.FullName
                ArgumentList = "/install /quiet /norestart /log $LogFile"
                NoNewWindow  = $true
                Wait         = $true
                PassThru     = $true
                ErrorAction  = "Continue"
            }
            $result = Start-Process @params
            Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
        }
        catch {
            throw $_
        }
    }
}

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:ProgramData\Microsoft\Windows\Start Menu\FSLogix\FSLogix Apps Online Help.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
