#Requires -RunAsAdministrator
<#
    .SYNOPSIS
        Uninstalls Citrix-related software agents from the system.

    .DESCRIPTION
        This script enumerates all installed software on the system and uninstalls applications published by
        Citrix Systems, Inc., UniDesk Corporation, or vast limits GmbH.
        It supports both MSI-based and non-MSI-based uninstallers, running them silently.

    .FUNCTIONS
        Get-InstalledSoftware
            Retrieves a list of installed software from the registry, including details such as name,
            version, publisher, uninstall string, and other properties.

        Uninstall-CitrixAgent
            Uninstalls a specified software application based on its properties, handling both MSI and non-MSI uninstallers.

    .PARAMETER Publishers
        An array of publisher names whose software should be targeted for uninstallation.

    .NOTES
        - Requires administrative privileges to uninstall software.

    .EXAMPLE
        .\Uninstall-CitrixAgents.ps1
        Runs the script and silently uninstalls all Citrix-related agents from the system.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [System.String[]] $Publishers = @("Citrix Systems, Inc.", "vast limits GmbH")
)

begin {
    function Write-LogFile {
        <#
        .SYNOPSIS
            This function creates or appends a line to a log file

        .DESCRIPTION
            This function writes a log line to a log file in the form synonymous with
            ConfigMgr logs so that tools such as CMtrace and SMStrace can easily parse
            the log file.  It uses the ConfigMgr client log format's file section
            to add the line of the script in which it was called.

        .PARAMETER  Message
            The message parameter is the log message you'd like to record to the log file

        .PARAMETER  LogLevel
            The logging level is the severity rating for the message you're recording. Like ConfigMgr
            clients, you have 3 severity levels available; 1, 2 and 3 from informational messages
            for FYI to critical messages that stop the install. This defaults to 1.

        .EXAMPLE
            PS C:\> Write-LogFile -Message 'Value1' -LogLevel 'Value2'
            This example shows how to call the Write-LogFile function with named parameters.

        .NOTES
            Constantin Lotz;
            Adam Bertram, https://github.com/adbertram/PowerShellTipsToWriteBy/blob/f865c4212284dc25fe613ca70d9a4bafb6c7e0fe/chapter_7.ps1#L5
    #>
        [CmdletBinding(SupportsShouldProcess = $false)]
        param (
            [Parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
            [System.String] $Message,

            [Parameter(Position = 1, Mandatory = $false)]
            [ValidateSet(1, 2, 3)]
            [System.Int16] $LogLevel = 1
        )

        begin {
            # Log file path
            $LogFile = "$Env:SystemRoot\Logs\Uninstall-CitrixAgents\Uninstall-CitrixAgents-$(Get-Date -Format "yyyy-MM-dd").log"
            if (!(Test-Path -Path "$Env:SystemRoot\Logs\Uninstall-CitrixAgents")) {
                New-Item -Path "$Env:SystemRoot\Logs\Uninstall-CitrixAgents" -ItemType "Directory" -ErrorAction "SilentlyContinue" -WhatIf:$false | Out-Null
            }
        }

        process {
            # Build the line which will be recorded to the log file
            $TimeGenerated = $(Get-Date -Format "HH:mm:ss.ffffff")
            $Date = Get-Date -Format "yyyy-MM-dd"
            $LineNumber = "$($MyInvocation.ScriptName | Split-Path -Leaf -ErrorAction "SilentlyContinue"):$($MyInvocation.ScriptLineNumber)"
            $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
            $Thread = $([Threading.Thread]::CurrentThread.ManagedThreadId)
            $LineFormat = $Message, $TimeGenerated, $Date, $LineNumber, $Context, $LogLevel, $Thread
            $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="{4}" type="{5}" thread="{6}" file="">' -f $LineFormat

            # Add content to the log file and output to the console
            Write-Information -MessageData "[$TimeGenerated] $Message" -InformationAction "Continue"
            Add-Content -Value $Line -Path $LogFile -WhatIf:$false

            # Write-Warning for log level 2 or 3
            if ($LogLevel -eq 3 -or $LogLevel -eq 2) {
                Write-Warning -Message "[$TimeGenerated] $Message"
            }
        }
    }

    function Get-InstalledSoftware {
        [CmdletBinding()]
        param ()
        $UninstallKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        $Apps = @()
        foreach ($Key in $UninstallKeys) {
            try {
                $propertyNames = "DisplayName", "DisplayVersion", "Publisher", "UninstallString", "PSPath", "WindowsInstaller", "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize", "SystemComponent"
                $Apps += Get-ItemProperty -Path $Key -Name $propertyNames -ErrorAction "SilentlyContinue" | `
                    . { process { if ($null -ne $_.DisplayName) { $_ } } } | `
                    Where-Object { $_.SystemComponent -ne 1 } | `
                    Select-Object -Property @{n = "Name"; e = { $_.DisplayName } }, @{n = "Version"; e = { $_.DisplayVersion } }, "Publisher", "UninstallString", @{n = "RegistryPath"; e = { $_.PSPath -replace "Microsoft.PowerShell.Core\\Registry::", "" } }, "PSChildName", "WindowsInstaller", "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize" | `
                    Sort-Object -Property "DisplayName", "Publisher"
            }
            catch {
                throw $_.Exception.Message
            }
        }

        Remove-PSDrive -Name "HKU" -ErrorAction "SilentlyContinue" | Out-Null
        return $Apps
    }

    function Uninstall-CitrixAgent {
        [CmdletBinding(SupportsShouldProcess = $true)]
        param (
            [System.Object[]]$Application
        )

        begin {
            $LogPath = "$Env:SystemRoot\Logs\Uninstall-CitrixAgents"
        }

        process {
            if ($Application.WindowsInstaller -eq 1) {
                $ArgumentList = "/uninstall `"$($Application.PSChildName)`" /quiet /norestart /log `"$LogPath\$($Application.PSChildName).log`""
                $params = @{
                    FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
                    ArgumentList = $ArgumentList
                    NoNewWindow  = $true
                    PassThru     = $true
                    Wait         = $true
                    ErrorAction  = "Continue"
                    Verbose      = $true
                }
                Write-LogFile -Message "Uninstall:  $($Application.Name) $($Application.Version)"
                Write-LogFile -Message "Executable: $Env:SystemRoot\System32\msiexec.exe"
                Write-LogFile -Message "Arguments:  $ArgumentList"
                if ($PSCmdlet.ShouldProcess("$Env:SystemRoot\System32\msiexec.exe", "Start process")) {
                    $result = Start-Process @params
                    Write-LogFile -Message "Uninstall return code: $($result.ExitCode)"
                }
            }
            else {
                # Split the uninstall string to extract the executable and arguments
                $String = $Application.UninstallString -replace "`"", "" -split ".exe"

                switch ($Application.UninstallString) {
                    { $Application -match "rundll32" } {
                        # Driver packages
                        $ArgumentList = "$($String[1].Trim())"
                    }
                    { $Application -match "bootstrapperhelper.exe" } {
                        # Citrix Workspace app
                        $ArgumentList = "$($String[1].Trim()) /silent /norestart"
                    }
                    { $Application -match "XenDesktopVdaSetup.exe" } {
                        # Citrix Virtual Desktop Agent
                        $ArgumentList = "/remove /REMOVE_APPDISK_ACK /REMOVE_PVD_ACK /quiet /noreboot"
                    }
                    default {
                        # Other non-MSI uninstallers
                        $ArgumentList = "$($String[1].Trim()) /quiet /norestart /log `"$LogPath\$(Split-Path $String[0].Trim() -Leaf).log`""
                    }
                }

                $params = @{
                    FilePath     = "$($String[0].Trim()).exe"
                    ArgumentList = $ArgumentList
                    NoNewWindow  = $true
                    PassThru     = $true
                    Wait         = $true
                    ErrorAction  = "Continue"
                    Verbose      = $true
                }
                Write-LogFile -Message "Uninstall:  $($Application.Name) $($Application.Version)"
                Write-LogFile -Message "Executable: $($String[0].Trim()).exe"
                Write-LogFile -Message "Arguments:  $ArgumentList"
                if ($PSCmdlet.ShouldProcess("$($String[0].Trim()).exe", "Start process")) {
                    $result = Start-Process @params
                    Write-LogFile -Message "Uninstall return code: $($result.ExitCode)"
                }
            }
        }
    }

    function Get-PendingFileRenameOperation {
        $Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
        $Value = "PendingFileRenameOperations"
        $FilesArray = Get-ItemProperty -Path $Path -Name $Value -ErrorAction "SilentlyContinue" | `
            Select-Object -ExpandProperty $Value -ErrorAction "SilentlyContinue"
        if ($null -ne $FilesArray) {
            if ($FilesArray.Count -ge 1) {
                [PSCustomObject]@{
                    RebootRequired = $true
                    Files          = ($FilesArray | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
                }
            }
        }
        else {
            [PSCustomObject]@{
                RebootRequired = $false
                Files          = $null
            }
        }
    }
}

process {
    # Get the list of Citrix agents to uninstall
    $CitrixAgents = Get-InstalledSoftware | Where-Object { $_.Publisher -in $Publishers }

    # Count the number of Citrix agents found
    if ($null -eq $CitrixAgents) {
        $AgentsCount = 0
    }
    elseif ($CitrixAgents -is [System.Array]) {
        $AgentsCount = $CitrixAgents.Count
    }
    elseif ($CitrixAgents -is [System.Management.Automation.PSCustomObject]) {
        $AgentsCount = 1
    }
    else {
        $AgentsCount = 0
    }

    # Uninstall Citrix agents based on the specified publishers
    Write-LogFile -Message "Found $AgentsCount Citrix agents for uninstallation:"
    $CitrixAgents | ForEach-Object { Write-LogFile -Message "  $($_.Name) $($_.Version)" }
    $CitrixAgents | ForEach-Object { Uninstall-CitrixAgent -Application $_ }
}

end {
    if ($AgentsCount -gt 0) {
        Write-LogFile -Message "Uninstallation of Citrix agents completed."
        $FilesPending = Get-PendingFileRenameOperation
        if ($FilesPending.RebootRequired -eq $true) {
            # List of directories to remove after uninstallation
            Write-LogFile -Message "Files remaining after uninstallation. Delete the following directories after rebooting:"
            "$Env:ProgramFiles\Citrix", "${Env:ProgramFiles(x86)}\Citrix", "${Env:ProgramFiles(x86)}\Common Files\Citrix" | `
                ForEach-Object { Write-LogFile -Message "$_" }
            Write-LogFile -Message "Please restart the system to finalize the process. $($FilesPending.Files.Count) files pending for deletion."
        }
        else {
            Write-LogFile -Message "No pending file rename operations detected."
        }
    }
    else {
        Write-LogFile -Message "No Citrix agents found for uninstallation."
    }
}
