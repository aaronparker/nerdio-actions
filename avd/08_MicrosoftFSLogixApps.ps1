#description: Installs the latest Microsoft FSLogix Apps agent
#execution mode: Combined
#tags: Evergreen, FSLogix
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\FSLogix"


#region Script logic
# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null
Write-Verbose -Message "Microsoft FSLogix Apps agent"

# Download
$App = Get-EvergreenApp -Name "MicrosoftFSLogixApps" | Where-Object { $_.Channel -eq "Production" } | Select-Object -First 1
Write-Verbose -Message "Microsoft FSLogix Apps agent: $($App.Version)."
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

# Unpack
try {
    Write-Verbose -Message "Unpacking: $($OutFile.FullName)."
    Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force
}
catch {
    Write-Verbose -Message "ERR:: Failed to unpack: $($OutFile.FullName)."
}

# Install
foreach ($file in "FSLogixAppsSetup.exe", "FSLogixAppsRuleEditorSetup.exe") {
    $Installers = Get-ChildItem -Path $Path -Recurse -Include $file | Where-Object { $_.Directory -match "x64" }
    foreach ($installer in $Installers) {
        Write-Verbose -Message "Installing: $($installer.FullName)."
        $params = @{
            FilePath     = $installer.FullName
            ArgumentList = "/install /quiet /norestart"
            NoNewWindow  = $True
            Wait         = $True
            PassThru     = $True
        }
        $result = Start-Process @params
        $Output = [PSCustomObject] @{
            Path     = $OutFile.FullName
            ExitCode = $result.ExitCode
        }
        Write-Verbose -Message -InputObject $Output
    }
}

Write-Verbose -Message "Complete: Microsoft FSLogix Apps."
#endregion
