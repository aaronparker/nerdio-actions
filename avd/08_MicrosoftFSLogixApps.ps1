#description: Installs the latest Microsoft FSLogix Apps agent
#execution mode: Combined
#tags: Evergreen, FSLogix
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\FSLogix"


#region Script logic
# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

try {
    # Download and unpack
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "MicrosoftFSLogixApps" | Where-Object { $_.Channel -eq "Production" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
    Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force
}
catch {
    throw $_.Exception.Message
}

try {
    # Install
    foreach ($file in "FSLogixAppsSetup.exe", "FSLogixAppsRuleEditorSetup.exe") {
        $Installers = Get-ChildItem -Path $Path -Recurse -Include $file | Where-Object { $_.Directory -match "x64" }
        foreach ($installer in $Installers) {
            try {
                $params = @{
                    FilePath     = $installer.FullName
                    ArgumentList = "/install /quiet /norestart /log `"$env:ProgramData\NerdioManager\Logs\MicrosoftFSLogixApps.log`""
                    NoNewWindow  = $True
                    Wait         = $True
                    PassThru     = $False
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
#endregion
