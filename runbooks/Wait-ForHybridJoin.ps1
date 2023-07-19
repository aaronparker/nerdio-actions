#description: Pause session host availability until Hybrid Azure AD join is complete. Run as a scripted action when VM is CREATED but after the VM is joined to the AVD host pool.
#execution mode: Combined
#tags: AAD

# Source: https://github.com/steve-prentice/autopilot/blob/master/WaitForUserDeviceRegistration.ps1

if ($null -eq $SecureVars.DeviceRegWait) {
    [System.String] $ScriptTimeout = 60 #minutes
}
else {
    [System.String] $ScriptTimeout = $SecureVars.DeviceRegWait
}

function Write-Msg ($Msg) {
    $params = @{
        MessageData       = "[$(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')] $Msg"
        InformationAction = "Continue"
        Tags              = "AzureVirtualDesktop"
    }
    Write-Information @params
}

# Start logging
Start-Transcript "$env:SystemRoot\Logs\WaitForUserDeviceRegistration.log"

$filter304 = @{
    LogName = 'Microsoft-Windows-User Device Registration/Admin'
    Id      = '304' # Automatic registration failed at join phase
}

$filter306 = @{
    LogName = 'Microsoft-Windows-User Device Registration/Admin'
    Id      = '306' # Automatic registration Succeeded
}

$filter334 = @{
    LogName = 'Microsoft-Windows-User Device Registration/Admin'
    Id      = '334' # Automatic device join pre-check tasks completed. The device can NOT be joined because a domain controller could not be located.
}

$filter335 = @{
    LogName = 'Microsoft-Windows-User Device Registration/Admin'
    Id      = '335' # Automatic device join pre-check tasks completed. The device is already joined.
}

$filter20225 = @{
    LogName = 'Application'
    Id      = '20225' # A dialled connection to RRAS has successfully connected.
}

# Wait for up to $UserDeviceRegistration_ScriptTimeout minutes, re-checking once a minute...
while ($counter++ -lt $ScriptTimeout) {
    $events304 = Get-WinEvent -FilterHashtable $filter304 -MaxEvents 1 -ErrorAction "SilentlyContinue"
    $events306 = Get-WinEvent -FilterHashtable $filter306 -MaxEvents 1 -ErrorAction "SilentlyContinue"
    $events334 = Get-WinEvent -FilterHashtable $filter334 -MaxEvents 1 -ErrorAction "SilentlyContinue"
    $events335 = Get-WinEvent -FilterHashtable $filter335 -MaxEvents 1 -ErrorAction "SilentlyContinue"
    $events20225 = Get-WinEvent -FilterHashtable $filter20225 -MaxEvents 1 -ErrorAction "SilentlyContinue"

    if ($events335.Count -gt 0) {
        break
    }
    elseif ($events306.Count -gt 0) {
        break
    }
    elseif ($events20225 -and $events334 -and !$events304) {
        Write-Msg -Msg "RRAS dialled successfully. Trying Automatic-Device-Join task to create userCertificate"
        Start-ScheduledTask "\Microsoft\Windows\Workplace Join\Automatic-Device-Join"
        Write-Msg -Msg "Sleeping for 60s"
        Start-Sleep -Seconds 60
    }
    else {
        Write-Msg -Msg "No events indicating successful device registration with Azure AD"
        Write-Msg -Msg "Sleeping for 60s"
        Start-Sleep -Seconds 60
        if ($events304) {
            Write-Msg -Msg "Trying Automatic-Device-Join task again"
            Start-ScheduledTask "\Microsoft\Windows\Workplace Join\Automatic-Device-Join"
            Write-Msg -Msg "Sleeping for 5s"
            Start-Sleep -Seconds 5
        }
    }
}

if ($events306) {
    Write-Msg -Msg $events306.Message
    Write-Msg -Msg "Exiting with return code 0"
    Stop-Transcript
    exit 0
}

if ($events335) { Write-Msg -Msg $events335.Message }
Write-Msg -Msg "Script complete"
Stop-Transcript
