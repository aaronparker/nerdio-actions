#description: Installs the latest Microsoft FSLogix Apps agent
#execution mode: Combined
#tags: Evergreen, FSLogix
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\FSLogix"


#region Script logic
# Create target folder
try {
    New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

    # Download
    $App = Get-EvergreenApp -Name "MicrosoftFSLogixApps" | Where-Object { $_.Channel -eq "Production" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

    # Unpack
    Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force

    # Install
    foreach ($file in "FSLogixAppsSetup.exe", "FSLogixAppsRuleEditorSetup.exe") {
        $Installers = Get-ChildItem -Path $Path -Recurse -Include $file | Where-Object { $_.Directory -match "x64" }
        foreach ($installer in $Installers) {
            Write-Verbose -Message "Installing: $($installer.FullName)."
            $params = @{
                FilePath     = $installer.FullName
                ArgumentList = "/install /quiet /norestart /log `"$env:ProgramData\NerdioManager\Logs\MicrosoftFSLogixApps.log`""
                NoNewWindow  = $True
                Wait         = $True
                PassThru     = $True
            }
            Start-Process @params
        }
    }
}
catch {
    throw $_.Exception.Message
}
#endregion
