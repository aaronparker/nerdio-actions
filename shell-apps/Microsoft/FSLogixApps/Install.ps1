$Context.Log("Installing FSLogix Apps")
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
$LogFile = "$Env:SystemRoot\Logs\ImageBuild\MicrosoftFSLogixApps.log"
foreach ($File in "FSLogixAppsSetup.exe") {
    $Installers = Get-ChildItem -Path $PWD -Recurse -Include $File | Where-Object { $_.Directory -match "x64" }
    foreach ($Installer in $Installers) {
        $LogFile = "$LogPath\$($Installer.Name)$($App.Version).log" -replace " ", ""
        Write-LogFile -Message "Installing Microsoft FSLogix Apps agent"
        $params = @{
            FilePath     = $Installer.FullName
            ArgumentList = "/install /quiet /norestart /log $LogFile"
            Wait         = $true
            NoNewWindow  = $true
            PassThru     = $true
            ErrorAction  = "Stop"
        }
        $result = Start-Process @params
        $Context.Log("Install complete. Return code: $($result.ExitCode)")
    }
}
$Context.Log("Install complete")
