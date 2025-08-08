$Context.Log("Installing FSLogix Apps")
New-Item -Path "$Env:SystemRoot\Logs\ImageBuild" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
$LogFile = "$Env:SystemRoot\Logs\ImageBuild\MicrosoftFSLogixApps.log"
foreach ($File in "FSLogixAppsSetup.exe") {
    $Installers = Get-ChildItem -Path $PWD -Recurse -Include $File | Where-Object { $_.Directory -match "x64" }
    foreach ($Installer in $Installers) {
        $LogFile = "$Env:Windows\Logs\$($Installer.Name)$($App.Version).log" -replace " ", ""
        $Context.Log("Installing Microsoft FSLogix Apps agent from: $($Installer.FullName)")
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
