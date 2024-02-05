#description: Configures Windows roles, features and capabilities. Enable/disable Windows roles and features
#execution mode: IndividualWithRestart
#tags: Roles, Features, Capabilities, Image

#region Script logic
# Add / Remove roles and features (requires reboot at end of deployment)
switch -Regex ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption) {
    #region Windows Server
    "Microsoft Windows Server*" {
        try {
            $params = @{
                FeatureName   = "Printing-XPSServices-Features", "AzureArcSetup"
                Online        = $true
                NoRestart     = $true
                WarningAction = "SilentlyContinue"
                ErrorAction   = "SilentlyContinue"
            }
            Write-Information -MessageData ":: Disable feature: 'Printing-XPSServices-Features'" -InformationAction "Continue"
            Disable-WindowsOptionalFeature @params
        }
        catch {
            $_.Exception.Message
        }

        try {
            $params = @{
                Name          = "RDS-RD-Server", "Server-Media-Foundation", "Search-Service", "NET-Framework-Core", "Remote-Assistance"
                WarningAction = "SilentlyContinue"
                ErrorAction   = "SilentlyContinue"
            }
            Write-Information -MessageData ":: Install Windows features" -InformationAction "Continue"
            Install-WindowsFeature @params

            # Remove Azure Arc Setup from running at sign-in
            reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AzureArcSetup" /f | Out-Null
        }
        catch {
            $_.Exception.Message
        }

        # Enable services
        if ((Get-WindowsFeature -Name "RDS-RD-Server").InstallState -eq "Installed") {
            foreach ($service in "Audiosrv", "WSearch") {
                try {
                    $params = @{
                        Name          = $service
                        StartupType   = "Automatic"
                        WarningAction = "SilentlyContinue"
                        ErrorAction   = "SilentlyContinue"
                    }
                    Write-Information -MessageData ":: Set service start to automatic: $service" -InformationAction "Continue"
                    Set-Service @params
                }
                catch {
                    $_.Exception.Message
                }
            }
        }

        break
    }
    #endregion

    #region Windows 11
    "Microsoft Windows 11 Enterprise*|Microsoft Windows 11 Pro*" {
        try {
            $params = @{
                FeatureName   = "Printing-XPSServices-Features", "SMB1Protocol", "WorkFolders-Client", "MicrosoftWindowsPowerShellV2Root", "MicrosoftWindowsPowerShellV2"
                Online        = $true
                NoRestart     = $true
                WarningAction = "SilentlyContinue"
                ErrorAction   = "SilentlyContinue"
            }
            Write-Information -MessageData ":: Disable Windows optional features" -InformationAction "Continue"
            Disable-WindowsOptionalFeature @params
        }
        catch {
            $_.Exception.Message
        }

        break
    }
    #endregion

    #region Windows 10
    "Microsoft Windows 10 Enterprise*|Microsoft Windows 10 Pro*" {
        try {
            $params = @{
                FeatureName   = "Printing-XPSServices-Features", "SMB1Protocol", "WorkFolders-Client", `
                    "FaxServicesClientPackage", "WindowsMediaPlayer", "MicrosoftWindowsPowerShellV2Root", `
                    "MicrosoftWindowsPowerShellV2"
                Online        = $true
                NoRestart     = $true
                WarningAction = "SilentlyContinue"
                ErrorAction   = "SilentlyContinue"
            }
            Write-Information -MessageData ":: Disable Windows optional features" -InformationAction "Continue"
            Disable-WindowsOptionalFeature @params
        }
        catch {
            $_.Exception.Message
        }

        try {
            $params = @{
                Name                   = "Media.WindowsMediaPlayer~~~~0.0.12.0", "XPS.Viewer~~~~0.0.1.0", `
                    "App.Support.QuickAssist~~~~0.0.1.0", "MathRecognizer~~~~0.0.1.0", `
                    "Browser.InternetExplorer~~~~0.0.11.0", "Print.Fax.Scan~~~~0.0.1.0"
                IncludeManagementTools = $true
                WarningAction          = "SilentlyContinue"
                ErrorAction            = "SilentlyContinue"
            }
            Write-Information -MessageData ":: Uninstall Windows optional features" -InformationAction "Continue"
            Uninstall-WindowsFeature @params
        }
        catch {
            $_.Exception.Message
        }

        break
    }
    #endregion

    default {
    }
}
