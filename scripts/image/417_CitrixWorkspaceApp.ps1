#description: Installs the latest version the Citrix Workspace app
#execution mode: Combined
#tags: Evergreen, Citrix
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Citrix\Workspace"

#region Use Secure variables in Nerdio Manager to pass a language
if ($null -eq $SecureVars.CtxWorkspaceStream) {
    [System.String] $Stream = "Current"
}
else {
    [System.String] $Stream = $SecureVars.CtxWorkspaceStream
}
#endregion

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "CitrixWorkspaceApp" | `
        Where-Object { $_.Stream -eq $Stream } | `
        Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}

try {
    Write-Information -MessageData ":: Install Citrix Workspace app" -InformationAction "Continue"
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = "/silent /noreboot /includeSSON /AutoUpdateCheck=Disabled EnableTracing=false EnableCEIP=False ADDLOCAL=ReceiverInside,ICA_Client,BCR_Client,DesktopViewer,AM,SSON,SELFSERVICE,WebHelper"
        NoNewWindow  = $true
        Wait         = $false
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    Start-Sleep -Seconds 120
    Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
}
catch {
    throw $_.Exception.Message
}

try {
    # Disable update tasks - assuming we're installing on a gold image or updates will be managed
    Get-Service -Name "CWAUpdaterService" -ErrorAction "SilentlyContinue" | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}
#endregion
