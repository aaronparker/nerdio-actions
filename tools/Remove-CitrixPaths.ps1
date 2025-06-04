<#
    .SYNOPSIS
    Removes specified Citrix and related directories and registry keys from the system.

    .DESCRIPTION
    This script deletes common Citrix, deviceTRUST, and Unidesk installation directories and registry entries from the local machine.
    It is intended for cleanup or uninstallation scenarios and must be run with administrator privileges.

    .PARAMETER FilePaths
    An array of file system paths to remove. Defaults to common Citrix, deviceTRUST, and Unidesk installation directories.

    .PARAMETER RegMatch
    An array of wildcard patterns to match registry keys for removal. Defaults to patterns matching Citrix, deviceTRUST, and Unidesk keys.

    .EXAMPLE
    .\Remove-CitrixPaths.ps1

    Removes the default Citrix, deviceTRUST, and Unidesk directories and registry keys.

    .NOTES
    - Supports -WhatIf, -Verbose.
    - Requires -Confirm:false to bypass confirmation prompts.
    - Requires administrator privileges.
    - Use with caution, as this will permanently delete files and registry keys.
#>

#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [System.String[]] $FilePaths = @("$Env:ProgramFiles\Citrix",
        "${Env:ProgramFiles(x86)}\Citrix",
        "${Env:ProgramFiles(x86)}\Common Files\Citrix",
        "$Env:ProgramData\Citrix",
        "$Env:ProgramData\deviceTRUST",
        "$Env:ProgramData\Unidesk"),

    [Parameter(Position = 1, Mandatory = $false)]
    [System.String] $RegMatch = "Citrix*|deviceTRUST*|Unidesk*"
)

begin {
    function Write-LogFile {
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
            Add-Content -Value $Line -Path $LogFile -WhatIf:$false

            # Write-Warning for log level 2 or 3
            if ($LogLevel -eq 3 -or $LogLevel -eq 2) {
                Write-Warning -Message "[$TimeGenerated] $Message"
            }
            else {
                # Add content to the log file and output to the console
                Write-Information -MessageData "[$TimeGenerated] $Message" -InformationAction "Continue"
            }
        }
    }

    Write-LogFile -Message "Removing Citrix related directories and registry paths."
}

process {
    # Remove directory paths
    $FilePaths | ForEach-Object {
        if (Test-Path -Path $_) {
            Write-LogFile -Message "Removing directory: $_"
            Remove-Item -Path $_ -Recurse -Force
        }
    }

    # Search the registry for matching keys and remove
    Get-ChildItem -Path "HKLM:\" -Recurse -ErrorAction "SilentlyContinue" | `
        Where-Object { $_.PSPath -match $RegMatch } | `
        Select-Object -ExpandProperty "PSPath" | ForEach-Object {
        try {
            $RegPath = $_
            Write-LogFile -Message "Removing registry key: $($RegPath -replace 'Microsoft.PowerShell.Core\\Registry::', '')"
            Remove-Item -Path $_ -Recurse -Force -ErrorAction "Stop"
        }
        catch {
            Write-LogFile -Message "Failed to remove registry key: $RegPath" -LogLevel 3
            Write-LogFile -Message "Exception reason: $($_.CategoryInfo.Reason)" -LogLevel 3
            Write-LogFile -Message "Error message: $($_.Exception.Message)" -LogLevel 3
        }
    }
}
