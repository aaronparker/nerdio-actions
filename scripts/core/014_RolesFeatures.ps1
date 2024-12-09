<#
.SYNOPSIS
Configures Windows roles, features, and capabilities by enabling or disabling Windows roles and features.

.DESCRIPTION
This script is used to configure Windows roles, features, and capabilities on different versions of Windows,
including Windows Server, Windows 11, and Windows 10. It enables or disables specific Windows roles and features based on the operating system version.
#>
[CmdletBinding(SupportsShouldProcess = $false)]
param()

#region Script logic
# Add / Remove roles and features (requires reboot at end of deployment)
switch -Regex ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption) {
    #region Windows Server
    "Microsoft Windows Server*" {
        $Features = @("Printing-XPSServices-Features", "AzureArcSetup", "WindowsServerBackupSnapin",
            "WindowsServerBackup", "WindowsAdminCenterSetup", "SystemDataArchiver", "WirelessNetworking")
        foreach ($Feature in $Features) {
            $params = @{
                FeatureName   = $Feature
                Online        = $true
                NoRestart     = $true
                WarningAction = "SilentlyContinue"
                ErrorAction   = "SilentlyContinue"
            }
            Disable-WindowsOptionalFeature @params
        }

        $Features = @("RDS-RD-Server", "Server-Media-Foundation", "Search-Service", "Remote-Assistance") # "NET-Framework-Core"
        foreach ($Feature in $Features) {
            $params = @{
                Name          = $Feature
                WarningAction = "SilentlyContinue"
                ErrorAction   = "SilentlyContinue"
            }
            Install-WindowsFeature @params
        }

        # Remove other capabilities
        $Capabilities = @("App.StepsRecorder~~~~0.0.1.0",
            "Browser.InternetExplorer~~~~0.0.11.0",
            "Downlevel.NLS.Sorting.Versions.Server~~~~0.0.1.0",
            "MathRecognizer~~~~0.0.1.0",
            "Media.WindowsMediaPlayer~~~~0.0.12.0",
            "Microsoft.Windows.MSPaint~~~~0.0.1.0",
            "Microsoft.Windows.PowerShell.ISE~~~~0.0.1.0",
            "Microsoft.Windows.WordPad~~~~0.0.1.0",
            "XPS.Viewer~~~~0.0.1.0")
        foreach ($Capability in $Capabilities) {
            & "$Env:SystemRoot\System32\dism.exe" /Online /Remove-Capability /CapabilityName:$Capability /NoRestart /Quiet
        }

        # Remove Azure Arc Setup from running at sign-in
        reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AzureArcSetup" /f | Out-Null

        # Remove unnecessary shortcuts
        Remove-Item -Path "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\Administrative Tools\Microsoft Azure services.lnk" -ErrorAction "SilentlyContinue"
        Remove-Item -Path "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\Azure Arc Setup.lnk" -ErrorAction "SilentlyContinue"

        # Enable services
        foreach ($service in "Audiosrv", "WSearch") {
            $params = @{
                Name          = $service
                StartupType   = "Automatic"
                WarningAction = "SilentlyContinue"
                ErrorAction   = "SilentlyContinue"
            }
            Set-Service @params
        }

        # Uninstall unnecessary applications
        foreach ($Path in "$Env:SystemRoot\System32\mspaint.exe", "$Env:SystemRoot\System32\mstsc.exe", "$Env:SystemRoot\System32\SnippingTool.exe") {
            if (Test-Path -Path $Path) {
                $params = @{
                    FilePath     = $Path
                    ArgumentList = "/uninstall /noPromptBeforeRestart"
                    Wait         = $true
                    NoNewWindow  = $true
                    ErrorAction  = "SilentlyContinue"
                }
                Start-Process @params
            }
        }

        break
    }
    #endregion

    #region Windows 11
    "Microsoft Windows 11 Enterprise*|Microsoft Windows 11 Pro*" {
        $Features = @("Printing-XPSServices-Features", "SMB1Protocol", "WorkFolders-Client", "MicrosoftWindowsPowerShellV2Root", "MicrosoftWindowsPowerShellV2")
        foreach ($Feature in $Features) {
            $params = @{
                FeatureName   = $Feature
                Online        = $true
                NoRestart     = $true
                WarningAction = "SilentlyContinue"
                ErrorAction   = "SilentlyContinue"
            }
            Disable-WindowsOptionalFeature @params
        }
        break
    }
    #endregion

    #region Windows 10
    "Microsoft Windows 10 Enterprise*|Microsoft Windows 10 Pro*" {
        $Features = @("Printing-XPSServices-Features", "SMB1Protocol", "WorkFolders-Client", `
                "FaxServicesClientPackage", "WindowsMediaPlayer", "MicrosoftWindowsPowerShellV2Root", `
                "MicrosoftWindowsPowerShellV2")
        foreach ($Feature in $Features) {
            $params = @{
                FeatureName   = $Feature
                Online        = $true
                NoRestart     = $true
                WarningAction = "SilentlyContinue"
                ErrorAction   = "SilentlyContinue"
            }
            Disable-WindowsOptionalFeature @params
        }

        $Features = @("Media.WindowsMediaPlayer~~~~0.0.12.0", "XPS.Viewer~~~~0.0.1.0", `
                "App.Support.QuickAssist~~~~0.0.1.0", "MathRecognizer~~~~0.0.1.0", `
                "Browser.InternetExplorer~~~~0.0.11.0", "Print.Fax.Scan~~~~0.0.1.0")
        foreach ($Feature in $Features) {
            $params = @{
                Name                   = $Feature
                IncludeManagementTools = $true
                WarningAction          = "SilentlyContinue"
                ErrorAction            = "SilentlyContinue"
            }
            Uninstall-WindowsFeature @params
        }
        break
    }
    #endregion

    default {
    }
}
