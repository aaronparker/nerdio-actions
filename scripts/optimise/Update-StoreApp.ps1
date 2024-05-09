<#
.SYNOPSIS
    Synchronously triggers store updates for a select set of apps. You should run this in
    legacy powershell.exe, as some of the code has problems in pwsh on older OS releases.
    https://github.com/microsoft/winget-cli/discussions/1738

    # Update all installed apps
    Get-AppxPackage | Where-Object { $_.NonRemovable -eq $false -and $_.IsFramework -eq $false } | .\Update-StoreApp.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [System.Collections.ArrayList] $PackageFamilyName = (
        "Microsoft.WindowsTerminal_8wekyb3d8bbwe",
        "Microsoft.WindowsCalculator_8wekyb3d8bbwe",
        "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe", # <-- winget comes from this one
        "Microsoft.WindowsNotepad_8wekyb3d8bbwe",
        "Microsoft.Paint_8wekyb3d8bbwe",
        "Microsoft.WindowsAlarms_8wekyb3d8bbwe".
        "Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe",
        "MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy",
        "Microsoft.WindowsStore_8wekyb3d8bbwe")
)

process {
    try {
        if ($PSVersionTable.PSVersion.Major -ne 5) {
            throw "This script has problems in pwsh on some platforms; please run it with legacy Windows PowerShell (5.1) (powershell.exe)."
        }

        # https://fleexlab.blogspot.com/2018/02/using-winrts-iasyncoperation-in.html
        Add-Type -AssemblyName "System.Runtime.WindowsRuntime"
        $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | `
                Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]

        function Await($WinRtTask, $ResultType) {
            $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
            $netTask = $asTask.Invoke($null, @($WinRtTask))
            $netTask.Wait(-1) | Out-Null
            $netTask.Result
        }

        # https://docs.microsoft.com/uwp/api/windows.applicationmodel.store.preview.installcontrol.appinstallmanager?view=winrt-22000
        # We need to tell PowerShell about this WinRT API before we can call it...
        Write-Verbose -Message "Enabling Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallManager WinRT type"
        [Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallManager, Windows.ApplicationModel.Store.Preview, ContentType = WindowsRuntime] | Out-Null
        $AppManager = New-Object -TypeName "Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallManager"

        foreach ($App in $PackageFamilyName) {
            try {
                Write-Verbose -Message "Requesting an update for: $App"
                $updateOp = $AppManager.UpdateAppByPackageFamilyNameAsync($App)
                $updateResult = Await $updateOp ([Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallItem])
                while ($true) {
                    if ($null -eq $updateResult) {
                        Write-Verbose -Message "Update is null. It must already be completed (or there was no update)."
                        break
                    }

                    if ($null -eq $updateResult.GetCurrentStatus()) {
                        Write-Verbose -Message "Current status is null."
                        break
                    }

                    Write-Progress -Activity $App -Status "Updating" -PercentComplete $updateResult.GetCurrentStatus().PercentComplete
                    if ($updateResult.GetCurrentStatus().PercentComplete -eq 100) {
                        #Write-Verbose -Message "Install completed ($App)"
                        break
                    }
                    Start-Sleep -Seconds 3
                }
                Write-Progress -Activity $App -Status "Updating" -Completed
            }
            catch [System.AggregateException] {
                # If the thing is not installed, we can't update it. In this case, we get an
                # ArgumentException with the message "Value does not fall within the expected
                # range." I cannot figure out why *that* is the error in the case of "app is
                # not installed"... perhaps we could be doing something different/better, but
                # I'm happy to just let this slide for now.
                $problem = $_.Exception.InnerException # we'll just take the first one
                Write-Verbose -Message "Error updating app $($App): $problem"
            }
            catch {
                Write-Error -Message "Unexpected error updating app $($App): $($_.Exception.Message)"
            }
        }
    }
    catch {
        throw $_
    }
}
