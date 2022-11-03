#description: Configures Windows roles, features and capabilities
#execution mode: IndividualWithRestart
#tags: Roles, Features, Capabilities
<#
    .SYNOPSIS
        Enable/disable Windows roles and features and set language/regional settings.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs progress to the pipeline log")]
[CmdletBinding()]
param ()

#region Script logic

# Run tasks
switch -Regex ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption) {
    "Microsoft Windows Server*" {
        # Add / Remove roles and features (requires reboot at end of deployment)
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
            Write-Warning -Message " ERR: Failed to set feature state with: $($_.Exception.Message)."
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
            Write-Warning -Message " ERR: Failed to set feature state with: $($_.Exception.Message)."
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
                    Write-Warning -Message " ERR: Failed to set service properties with: $($_.Exception.Message)."
                }
            }
        }
        break
    }
    "Microsoft Windows 1* Enterprise for Virtual Desktops" {
        break
    }
    "Microsoft Windows 1* Enterprise" {
        break
    }
    "Microsoft Windows 1*" {
        break
    }
    default {
    }
}
