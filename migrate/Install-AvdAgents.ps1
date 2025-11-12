#Requires -RunAsAdministrator
<#
    .SYNOPSIS
        Installs required agents and dependencies for Microsoft Azure Virtual Desktop (AVD) environments.

    .DESCRIPTION
        This script automates the installation of essential components for Azure Virtual Desktop, including:
        - Microsoft Visual C++ Redistributable packages (x64 and x86)
        - Microsoft Azure Virtual Desktop WebRTC installer
        - Microsoft Azure Virtual Desktop Multimedia Redirection Extensions

        It also sets the required registry value for Microsoft Teams to recognize the AVD environment.

    .PARAMETER Path
        The directory path where the installers will be downloaded. Defaults to the system temporary directory.

    .FUNCTIONS
        Resolve-Url
            Resolves a given URL, following redirects, and returns response details including the final URI.
        Invoke-DownloadFile
            Downloads a file from a specified URI to a given output file path.
        Install-Msi
            Installs an MSI package silently using msiexec.
        Install-Exe
            Installs an EXE installer silently.

    .NOTES
        - Requires administrative privileges to install software and modify the registry.
        - Enables TLS 1.2 for secure downloads.
        - Designed for use in automated provisioning or image preparation for AVD/W365 environments.

    .LINK
        https://learn.microsoft.com/en-us/windows-365/enterprise/device-images

    .EXAMPLE
        .\Install-AvdAgents.ps1
        Installs all required AVD agents and dependencies using default temporary directory.

        .\Install-AvdAgents.ps1 -Path "C:\Installers"
        Installs all required AVD agents and dependencies using the specified path to store installers.
#>
[CmdletBinding(SupportsShouldProcess = $false)]
param (
    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter] $InstallFSLogixAgent,

    [Parameter(Mandatory = $false)]
    [System.String] $TempPath = $(Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath $(New-Guid))
)

begin {
    #region Functions
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
            $LogFile = "$Env:SystemRoot\Logs\Install-AvdAgents\Install-AvdAgents-$(Get-Date -Format "yyyy-MM-dd").log"
            if (!(Test-Path -Path "$Env:SystemRoot\Logs\Install-AvdAgents")) {
                New-Item -Path "$Env:SystemRoot\Logs\Install-AvdAgents" -ItemType "Directory" -ErrorAction "SilentlyContinue" -WhatIf:$false | Out-Null
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

    function Resolve-Url {
        param (
            [Parameter(Mandatory = $true, Position = 0)]
            [ValidateNotNullOrEmpty()]
            [System.String] $Uri,

            [Parameter()]
            [ValidateNotNullOrEmpty()]
            [System.Int32] $MaximumRedirection = 1
        )

        try {
            Write-LogFile -Message "Resolving URL: $Uri"
            $httpWebRequest = [System.Net.WebRequest]::Create($Uri)
            $httpWebRequest.MaximumAutomaticRedirections = $MaximumRedirection
            $httpWebRequest.AllowAutoRedirect = $true
            $webResponse = $httpWebRequest.GetResponse()

            # Construct the output; Return the custom object to the pipeline
            $PSObject = [PSCustomObject] @{
                LastModified  = $webResponse.LastModified
                ContentLength = $webResponse.ContentLength
                Headers       = $webResponse.Headers
                ResponseUri   = $webResponse.ResponseUri
                StatusCode    = $webResponse.StatusCode
            }
            Write-Output -InputObject $PSObject
            Write-LogFile -Message "Resolved URL: $($webResponse.ResponseUri.AbsoluteUri)"
        }
        catch {
            Write-LogFile -Message "Failed with: $($_.Exception.Message)" -LogLevel 3
            throw $_
        }
        finally {
            $webResponse.Dispose()
        }
    }

    function Invoke-DownloadFile {
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [System.String] $Uri,

            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [System.String] $OutFile
        )

        if (Test-Path -Path $OutFile -PathType "Leaf") {
            Write-LogFile -Message "File already exists at: $OutFile" -LogLevel 1
            return $OutFile
        }
        else {
            try {
                $ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
                Write-LogFile -Message "Downloading file from: $Uri"
                Write-LogFile -Message "Saving file to: $OutFile"
                $params = @{
                    Uri             = $Uri
                    OutFile         = $OutFile
                    UseBasicParsing = $true
                    ErrorAction     = "Stop"
                }
                Invoke-WebRequest @params
                if (Test-Path -Path $OutFile) {
                    Write-LogFile -Message "Downloaded file to: $OutFile"
                    return $OutFile
                }
                else {
                    Write-LogFile -Message "Failed with: $($_.Exception.Message)" -LogLevel 3
                    return $null
                }
            }
            catch {
                throw $_
            }
        }
    }

    function Install-Msi {
        param (
            [Parameter(Mandatory = $true, Position = 0)]
            [ValidateNotNullOrEmpty()]
            [System.String] $Path
        )

        try {
            Write-LogFile -Message "Running: $Env:SystemRoot\System32\msiexec.exe /install $Path /quiet /norestart"
            $params = @{
                FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
                ArgumentList = "/package `"$Path`" ALLUSERS=1 /quiet /norestart"
                NoNewWindow  = $true
                PassThru     = $true
                Wait         = $true
                ErrorAction  = "Continue"
                Verbose      = $false
            }
            $result = Start-Process @params
            Write-LogFile -Message "Install result: $($result.ExitCode)" -LogLevel 1
            return $result.ExitCode
        }
        catch {
            Write-LogFile -Message "Failed with: $($_.Exception.Message)" -LogLevel 3
            throw $_
        }
    }

    function Install-Exe {
        param (
            [Parameter(Mandatory = $true, Position = 0)]
            [ValidateNotNullOrEmpty()]
            [System.String] $Path
        )

        try {
            Write-LogFile -Message "Running: $Path /install /quiet /norestart"
            $params = @{
                FilePath     = $Path
                ArgumentList = "/install /quiet /norestart"
                NoNewWindow  = $true
                PassThru     = $true
                Wait         = $true
                ErrorAction  = "Continue"
                Verbose      = $false
            }
            $result = Start-Process @params
            Write-LogFile -Message "Install result: $($result.ExitCode)" -LogLevel 1
            return $result.ExitCode
        }
        catch {
            Write-LogFile -Message "Failed with: $($_.Exception.Message)" -LogLevel 3
            throw $_
        }
    }
    #endregion

    # Enable TLS 1.2
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    # Create temporary directory if it does not exist
    if (!(Test-Path -Path $TempPath -PathType "Container")) {
        Write-LogFile -Message "Creating temporary directory: $TempPath"
        New-Item -Path $TempPath -ItemType "Directory" -ErrorAction "SilentlyContinue" | Out-Null
    }

    $ReturnCodes = @()
}

process {
    #region Install the latest Microsoft Visual C++ Redistributable packages
    Write-LogFile -Message ">> Installing Microsoft Visual C++ Redistributables."
    foreach ($Url in "https://aka.ms/vs/17/release/VC_redist.x64.exe", "https://aka.ms/vs/17/release/VC_redist.x86.exe") {
        $VcRedist = Resolve-Url -Uri $Url
        $params = @{
            Uri     = $VcRedist.ResponseUri.AbsoluteUri
            OutFile = $(Join-Path -Path $TempPath -ChildPath $(Split-Path -Path $VcRedist.ResponseUri.AbsoluteUri -Leaf))
        }
        $Installer = Invoke-DownloadFile @params
        if ($Installer) {
            $ReturnCodes += Install-Exe -Path $Installer
        }
    }
    #endregion


    # Set required IsWVDEnvironment registry value
    Write-LogFile -Message ">> Setting registry value for IsWVDEnvironment."
    reg add "HKLM\SOFTWARE\Microsoft\Teams" /v "IsWVDEnvironment" /d 1 /t "REG_DWORD" /f *> $null

    #region Install the Microsoft Azure Virtual Desktop WebRTC installer
    Write-LogFile -Message ">> Installing Microsoft Azure Virtual Desktop WebRTC."
    $WebRtcUrl = Resolve-Url -Uri "https://aka.ms/msrdcwebrtcsvc/msi"
    $params = @{
        Uri     = $WebRtcUrl.ResponseUri.AbsoluteUri
        OutFile = $(Join-Path -Path $TempPath -ChildPath $(Split-Path -Path $WebRtcUrl.ResponseUri.AbsoluteUri -Leaf))
    }
    $Installer = Invoke-DownloadFile @params
    if ($Installer) {
        $ReturnCodes += Install-Msi -Path $Installer
    }
    #endregion


    #region Install the Microsoft Azure Virtual Desktop Multimedia Redirection Extensions
    Write-LogFile -Message ">> Installing Microsoft Azure Virtual Desktop Multimedia Redirection Extensions."
    $WebMmrUrl = Resolve-Url -Uri "https://aka.ms/avdmmr/msi"
    $params = @{
        Uri     = $WebMmrUrl.ResponseUri.AbsoluteUri
        OutFile = $(Join-Path -Path $TempPath -ChildPath $(Split-Path -Path $WebMmrUrl.ResponseUri.AbsoluteUri -Leaf))
    }
    $Installer = Invoke-DownloadFile @params
    if ($Installer) {
        $ReturnCodes += Install-Msi -Path $Installer
    }
    #endregion


    #region Install the FSLogix agent
    if ($InstallFSLogixAgent) {
        Write-LogFile -Message ">> Installing Microsoft FSLogix Agent."
        $FslogixUrl = Resolve-Url -Uri "https://aka.ms/fslogix/download" -MaximumRedirection 2
        $params = @{
            Uri     = $FslogixUrl.ResponseUri.AbsoluteUri
            OutFile = $(Join-Path -Path $TempPath -ChildPath $(Split-Path -Path $FslogixUrl.ResponseUri.AbsoluteUri -Leaf))
        }
        $Installer = Invoke-DownloadFile @params
        Expand-Archive -Path $Installer -DestinationPath $TempPath -Force -ErrorAction "SilentlyContinue"
        $Installer = Get-ChildItem -Path $TempPath -Filter "FSLogixAppsSetup.exe" -Recurse -File | Select-Object -First 1
        if ($Installer) {
            $ReturnCodes += Install-Exe -Path $Installer.FullName
        }
    }
    #endregion
}

end {
    Write-LogFile -Message "Cleaning up files in: $TempPath"
    Remove-Item -Path $TempPath -Recurse -Force -ErrorAction "SilentlyContinue"
    Write-LogFile -Message "Installation of AVD agents and dependencies completed."
    if (3010 -in $ReturnCodes) {
        Write-LogFile -Message "A reboot is required to complete the installation." -LogLevel 2
    }
}
