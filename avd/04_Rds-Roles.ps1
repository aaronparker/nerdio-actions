#description: Configures Windows roles, features and capabilities. Enable/disable Windows roles and features
#execution mode: IndividualWithRestart
#tags: Roles, Features, Capabilities

#region Script logic
# Add / Remove roles and features (requires reboot at end of deployment)
switch -Regex ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption) {
    "Microsoft Windows Server*" {
        try {
            $params = @{
                FeatureName   = "Printing-XPSServices-Features"
                Online        = $true
                NoRestart     = $true
                WarningAction = "Continue"
                ErrorAction   = "Continue"
            }
            Disable-WindowsOptionalFeature @params
        }
        catch {
            throw $_.Exception.Message
        }

        try {
            $params = @{
                Name                   = "EnhancedStorage", "PowerShell-ISE"
                IncludeManagementTools = $true
                WarningAction          = "Continue"
                ErrorAction            = "Continue"
            }
            Uninstall-WindowsFeature @params
        }
        catch {
            throw $_.Exception.Message
        }

        $params = @{
            Name          = "RDS-RD-Server", "Server-Media-Foundation", "Search-Service", "NET-Framework-Core", "Remote-Assistance"
            WarningAction = "Continue"
            ErrorAction   = "Continue"
        }
        Install-WindowsFeature @params

        # Enable services
        if ((Get-WindowsFeature -Name "RDS-RD-Server").InstallState -eq "Installed") {
            foreach ($service in "Audiosrv", "WSearch") {
                try {
                    $params = @{
                        Name          = $service
                        StartupType   = "Automatic"
                        WarningAction = "Continue"
                        ErrorAction   = "Continue"
                    }
                    Set-Service @params
                }
                catch {
                    throw $_.Exception.Message
                }
            }
        }
        break
    }
    "Microsoft Windows 1* Enterprise for Virtual Desktops|Microsoft Windows 1* Enterprise|Microsoft Windows 1*" {
        try {
            $params = @{
                FeatureName   = "Printing-XPSServices-Features", "SMB1Protocol", "WorkFolders-Client", `
                    "FaxServicesClientPackage", "WindowsMediaPlayer", "MicrosoftWindowsPowerShellV2Root", `
                    "MicrosoftWindowsPowerShellV2"
                Online        = $true
                NoRestart     = $true
                WarningAction = "Continue"
                ErrorAction   = "Continue"
            }
            Disable-WindowsOptionalFeature @params
        }
        catch {
            throw $_.Exception.Message
        }
        
        try {
            $params = @{
                Name                   = "Media.WindowsMediaPlayer~~~~0.0.12.0", "XPS.Viewer~~~~0.0.1.0", `
                    "App.Support.QuickAssist~~~~0.0.1.0", "MathRecognizer~~~~0.0.1.0", `
                    "Browser.InternetExplorer~~~~0.0.11.0", "Print.Fax.Scan~~~~0.0.1.0"
                IncludeManagementTools = $true
                WarningAction          = "Continue"
                ErrorAction            = "Continue"
            }
            Uninstall-WindowsFeature @params
        }
        catch {
            throw $_.Exception.Message
        }

        break
    }
    default {
    }
}

# Enable services
if ((Get-WindowsFeature -Name "RDS-RD-Server").InstallState -eq "Installed") {
    foreach ($service in "Audiosrv", "WSearch") {
        try {
            $params = @{
                Name          = $service
                StartupType   = "Automatic"
                WarningAction = "Continue"
                ErrorAction   = "Continue"
            }
            Set-Service @params
        }
        catch {
            throw $_.Exception.Message
        }
    }
}
