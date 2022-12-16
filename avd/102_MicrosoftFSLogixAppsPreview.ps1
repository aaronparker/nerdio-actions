#description: Installs the latest Microsoft FSLogix Apps agent - Public Preview
#execution mode: Combined
#tags: Evergreen, Microsoft, FSLogix, Preview
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\FSLogix"


#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# There's no preview right now, so exit the script
exit 0

try {
    # Download and unpack
    # Import-Module -Name "Evergreen" -Force
    # $App = Invoke-EvergreenApp -Name "MicrosoftFSLogixApps" | Where-Object { $_.Channel -eq "Production" } | Select-Object -First 1
    $App = [PSCustomObject]@{
        Version = "2.9.8308.44092"
        URI = "https://download.microsoft.com/download/5/d/0/5d02445f-18b4-4c94-9f17-e65f06207593/FSLogix_Apps_2.9.8308.44092.zip"
    }
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
    Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force
}
catch {
    throw $_
}

try {
    # Install
    foreach ($file in "FSLogixAppsSetup.exe", "FSLogixAppsRuleEditorSetup.exe") {
        $Installers = Get-ChildItem -Path $Path -Recurse -Include $file | Where-Object { $_.Directory -match "x64" }
        foreach ($Installer in $Installers) {
            try {
                $LogFile = "$env:ProgramData\Evergreen\Logs\$($Installer.Name)$($App.Version).log" -replace " ", ""
                $params = @{
                    FilePath     = $Installer.FullName
                    ArgumentList = "/install /quiet /norestart /log $LogFile"
                    NoNewWindow  = $true
                    Wait         = $true
                    PassThru     = $false
                }
                $result = Start-Process @params
            }
            catch {
                throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
            }
        }
    }
}
catch {
    throw $_.Exception.Message
}

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:ProgramData\Microsoft\Windows\Start Menu\FSLogix\FSLogix Apps Online Help.lnk")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
