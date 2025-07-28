#Requires -Module Az.Accounts, Az.Storage, Evergreen
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "", Justification = "Credentials are protected locally.")]
param (
    [Parameter(Mandatory = $false)]
    [System.String] $EnvironmentFile = "/Users/aaron/projects/nerdio-actions/api/environment.json",

    [Parameter(Mandatory = $false)]
    [System.String] $CredentialsFile = "/Users/aaron/projects/nerdio-actions/api/creds.json"
)

# Read environment variables and credentials
$ErrorActionPreference = "Stop"
$script:env = Get-Content -Path $EnvironmentFile | ConvertFrom-Json
$script:creds = Get-Content -Path $CredentialsFile | ConvertFrom-Json

function Connect-Nme {
    try {
        $params = @{
            Uri             = "https://login.microsoftonline.com/$($script:creds.TenantId)/oauth2/v2.0/token"
            Body            = @{
                "grant_type"  = "client_credentials"
                scope         = $script:creds.ApiScope
                client_id     = $script:creds.ClientId
                client_secret = $script:creds.ClientSecret
            }
            Headers         = @{
                "Accept"        = "application/json, text/plain, */*"
                "Content-Type"  = "application/x-www-form-urlencoded"
                "Cache-Control" = "no-cache"
            }
            Method          = "POST"
            UseBasicParsing = $true
        }
        $script:Token = Invoke-RestMethod @params
        Write-Host -ForegroundColor "Green" "Authenticated to Nerdio Manager."
        Write-Host -ForegroundColor "Cyan" "Token expires: $((Get-Date).AddSeconds($script:Token.expires_in).ToString())"
    }
    catch {
        throw "Failed to authenticate to Nerdio Manager: $($_.Exception.Message)"
    }
}

function Get-MD5Hash {
    param (
        [Parameter(Mandatory)]
        [System.String] $InputString
    )

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $hash = $md5.ComputeHash($bytes)
    -join ($hash | ForEach-Object { $_.ToString('x2') })
}

function Get-RemoteFileHash {
    param (
        [Parameter(Mandatory = $true)]
        [System.String] $Url
    )
    try {
        $WebClient = [System.Net.WebClient]::new()
        Write-Host -ForegroundColor "Cyan" "Opening remote stream: $Url"
        $Stream = $WebClient.OpenRead($Url)
        if ($null -eq $Stream) {
            throw "Failed to open remote stream. Stream is null."
        }
        Write-Host -ForegroundColor "Cyan" "Calculating SHA256 hash."
        $hash = Get-FileHash -Algorithm "SHA256" -InputStream $Stream
        Write-Host -ForegroundColor "Cyan" "Hash: $($hash.Hash)"
        return $hash.Hash
    }
    catch {
        Write-Error "Error occurred: $($_.Exception.Message)"
    }
    finally {
        if ($Stream) { $Stream.Dispose() }
        if ($WebClient) { $WebClient.Dispose() }
    }
}

function Get-EvergreenAppDetail {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [PSCustomObject] $Definition
    )

    process {
        Write-Host -ForegroundColor "Cyan" "Query Evergreen: $($Definition.source.app)"
        Write-Host -ForegroundColor "Cyan" "Filter: $($Definition.source.filter)"
        $AppDetail = Get-EvergreenApp -Name $Definition.source.app | Where-Object { Invoke-Expression "$($Definition.source.filter)" }
        Write-Host -ForegroundColor "Cyan" "Found version $($AppDetail.Version)"
        return $AppDetail
    }
}

function Get-ShellAppDefinition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String] $Path
    )

    begin {
        $ErrorActionPreference = "Stop"
    }
    process {
        if (Test-Path -Path $Path -PathType "Container") {
            Write-Host -ForegroundColor "Cyan" "Reading Shell App definition from: $Path"
            $Definition = Get-Content -Path (Join-Path -Path $Path -ChildPath "Definition.json") | ConvertFrom-Json
            $InstallScript = Get-Content -Path (Join-Path -Path $Path -ChildPath "Install.ps1") -Raw
            $UninstallScript = Get-Content -Path (Join-Path -Path $Path -ChildPath "Uninstall.ps1") -Raw
            $DetectScript = Get-Content -Path (Join-Path -Path $Path -ChildPath "Detect.ps1") -Raw
            $Definition.detectScript = $DetectScript
            $Definition.installScript = $InstallScript
            $Definition.uninstallScript = $UninstallScript
            return $Definition
        }
        else {
            Write-Error -Message "Path does not exist or is not a directory: $Path"
            return $null
        }
    }
}

function Get-ShellApp {
    [CmdletBinding()]
    param ()
    process {
        # Get existing Shell Apps
        $params = @{
            Uri             = "https://$($env.nmeHost)/api/v1/shell-app"
            Headers         = @{
                "Accept"        = "application/json; utf-8"
                "Authorization" = "Bearer $($script:Token.access_token)"
                "Content-Type"  = "application/x-www-form-urlencoded"
                "Cache-Control" = "no-cache"
            }
            Method          = "GET"
            UseBasicParsing = $true
        }
        Invoke-RestMethod @params
    }
}

function Get-ShellAppVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [System.String] $Id
    )
    begin {
    }
    process {
        # Get versions of existing Shell App
        $params = @{
            Uri             = "https://$($env.nmeHost)/api/v1/shell-app/$Id/version"
            Headers         = @{
                "Accept"        = "application/json; utf-8"
                "Authorization" = "Bearer $($script:Token.access_token)"
                "Content-Type"  = "application/x-www-form-urlencoded"
                "Cache-Control" = "no-cache"
            }
            Method          = "GET"
            UseBasicParsing = $true
        }
        Invoke-RestMethod @params
    }
}

function New-ShellAppFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $AppDetail,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $UseRemoteUrl,

        [Parameter(Mandatory = $false)]
        [System.String] $TempPath = "/Users/aaron/Temp/shell-apps"
    )

    if ($UseRemoteUrl) {
        # Use the remote URL to get the file
        if ($null -eq $AppDetail.Sha256) {
            $Sha256 = Get-RemoteFileHash -Url $AppDetail.URI
        }
        else {
            Write-Host -ForegroundColor "Cyan" "Using provided SHA256 hash: $($AppDetail.Sha256)"
            $Sha256 = $AppDetail.Sha256
        }

        # Create a PSCustomObject with the file details
        $Output = [PSCustomObject] @{
            Sha256    = $Sha256
            FileType  = [System.IO.Path]::GetExtension($AppDetail.URI).TrimStart('.')
            SourceUrl = $AppDetail.URI
        }
        return $Output
    }
    else {
        # Download the application binary
        New-Item -Path $TempPath -ItemType "Directory" -Force | Out-Null
        $File = $AppDetail | Save-EvergreenApp -LiteralPath $TempPath
        Write-Host -ForegroundColor "Cyan" "Downloaded file: $($File.FullName)"

        # Determine the SHA256 hash of the file
        if ($null -eq $AppDetail.Sha256) {
            $Sha256 = (Get-FileHash -Path $File.FullName -Algorithm "SHA256").Hash
        }
        else {
            $Sha256 = $AppDetail.Sha256
        }

        # Get storage account key; Create storage context
        Write-Host -ForegroundColor "Cyan" "Get storage acccount key from: $($script:env.resourceGroupName) / $($script:env.storageAccountName)"
        $StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $script:env.resourceGroupName -Name $script:env.storageAccountName)[0].Value
        $Context = New-AzStorageContext -StorageAccountName $script:env.storageAccountName -StorageAccountKey $StorageAccountKey

        # Upload file to blob container
        # Permissions required: "Storage Blob Data Contributor"
        $BlobName = "$(Get-MD5Hash -InputString $Sha256).$(Split-Path -Path $File.FullName -Leaf)"
        Write-Host -ForegroundColor "Cyan" "Uploading file to blob: $BlobName"
        $params = @{
            File      = $File.FullName
            Container = $script:env.containerName
            Blob      = $BlobName
            Context   = $Context
            Force     = $true
        }
        $BlobFile = Set-AzStorageBlobContent @params
        if ($null -eq $BlobFile.ICloudBlob.Uri.AbsoluteUri) {
            Write-Error -Message "Failed to upload blob file to storage account."
            exit 1
        }
        else {
            Write-Host -ForegroundColor "Cyan" "Uploaded file to blob: $($BlobFile.ICloudBlob.Uri.AbsoluteUri)"
        }

        # Get a SAS token for the blob
        $params = @{
            Context    = $Context
            Container  = $script:env.containerName
            Blob       = $BlobName
            Permission = "r"
            ExpiryTime = (Get-Date).AddYears(10)
            FullUri    = $true
        }
        $SasToken = New-AzStorageBlobSASToken @params

        # Determine the source URL, if a SAS token is provided, use it; otherwise, use the blob URI
        if ($SasToken) {
            Write-Host -ForegroundColor "Cyan" "Using SAS token for source URL."
            $SourceUrl = $SasToken
        }
        else {
            Write-Host -ForegroundColor "Cyan" "Using blob URI for source URL."
            $SourceUrl = $BlobFile.ICloudBlob.Uri.AbsoluteUri
        }

        # Create a PSCustomObject with the file details
        $Output = [PSCustomObject] @{
            Sha256    = $Sha256
            FileType  = $File.Extension.TrimStart('.')
            SourceUrl = $SourceUrl
        }
        return $Output
    }
}

function New-ShellApp {
    <#
    .SYNOPSIS
        Automates the import and creation of a Nerdio Manager Shell App using application definitions and scripts.

    .DESCRIPTION
        This script streamlines the process of importing a Shell App into Nerdio Manager by:
        - Reading app definitions and scripts from a specified directory.
        - Querying the latest application version and download URL using the Evergreen module.
        - Optionally downloading the application binary and uploading it to Azure Blob Storage.
        - Calculating the SHA256 hash of the application binary.
        - Updating the app definition with version, source URL, and hash.
        - Creating the Shell App in Nerdio Manager via its API.

    .PARAMETER AppPath
        Path(s) to the directory containing the Shell App definition and scripts. Defaults to a Visual Studio Code app path.

    .PARAMETER EnvironmentFile
        Path to the JSON file containing environment variables such as resource group, storage account, and Nerdio Manager host.

    .PARAMETER CredentialsFile
        Path to the JSON file containing Azure and Nerdio Manager credentials.

    .PARAMETER TempPath
        Temporary directory path for storing downloaded application binaries.

    .PARAMETER UseRemoteUrl
        Switch to use the remote application URL directly instead of downloading and uploading to Azure Blob Storage.

    .NOTES
        - Requires Az.Accounts, Az.Storage, and Evergreen PowerShell modules.
        - Credentials are read from local JSON files and are not transmitted in plain text.
        - Azure authentication uses device authentication; update for managed identity in CI/CD pipelines.
        - Requires "Storage Blob Data Contributor" permissions to upload to Azure Blob Storage.

    .EXAMPLE
        .\New-ShellApp.ps1 -AppPath "C:\Apps\MyShellApp" -EnvironmentFile ".\env.json" -CredentialsFile ".\creds.json"

    .LINK
        https://github.com/aaron/projects/nerdio-actions
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $Definition,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $AppDetail,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $UseRemoteUrl
    )
    process {
        try {
            # Create a file object for the Shell App
            $params = @{
                AppDetail    = $AppDetail
                UseRemoteUrl = $UseRemoteUrl
            }
            $File = New-ShellAppFile @params

            # Update the app definition
            if ($File.FileType -eq "zip") {
                Write-Host -ForegroundColor "Cyan" "Using fileUnzip: true for zip files."
                $Definition.fileUnzip = $true
            }
            $Definition.versions[0].name = $AppDetail.Version
            $Definition.versions[0].file.sourceUrl = $File.SourceUrl
            $Definition.versions[0].file.sha256 = $File.Sha256
            $DefinitionJson = $Definition | Select-Object -ExcludeProperty "source" | ConvertTo-Json -Depth 10

            # Create the Shell App in Nerdio Manager
            if ($script:Token) {
                $params = @{
                    Uri             = "https://$($script:env.nmeHost)/api/v1/shell-app"
                    Method          = "POST"
                    Headers         = @{
                        "accept"        = "application/json"
                        "Authorization" = "Bearer $($script:Token.access_token)"
                    }
                    Body            = $DefinitionJson
                    ContentType     = "application/json"
                    UseBasicParsing = $true
                }
                $Result = Invoke-RestMethod @params
                if ($Result.job.status -eq "Completed") {
                    Write-Host -ForegroundColor "Green" "Shell App created successfully. Id: $($Result.job.id)"
                }
                else {
                    Write-Host -ForegroundColor "Red" "Failed to create Shell App. Status: $($Result.job.status)"
                }
            }
        }
        catch {
            $lineNumber = $_.InvocationInfo.ScriptLineNumber
            $scriptName = $_.InvocationInfo.ScriptName
            $errorMsg = $_.Exception.Message
            Write-Error -Message "Error on line $lineNumber in ${scriptName}: $errorMsg"
        }
    }
}

function New-ShellAppVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [System.String] $Id,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $AppDetail,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $UseRemoteUrl
    )
    process {
        # Create the Shell App version in Nerdio Manager
        try {
            # Create a file object for the Shell App version
            $params = @{
                AppDetail    = $AppDetail
                UseRemoteUrl = $UseRemoteUrl
            }
            $File = New-ShellAppFile @params

            # Definition required for a Shell App version
            $Definition = @"
{
    "name": "#version",
    "isPreview": false,
    "installScriptOverride": null,
    "file": {
        "sourceUrl": "#sourceUrl",
        "sha256": "#sha256"
    }
}
"@ | ConvertFrom-Json -Depth 10

            # Update the app definition with the new version details
            $Definition.name = $AppDetail.Version
            $Definition.file.sourceUrl = $File.SourceUrl
            $Definition.file.sha256 = $File.Sha256
            $DefinitionJson = $Definition | ConvertTo-Json -Depth 10

            if ($script:Token) {
                $params = @{
                    Uri             = "https://$($script:env.nmeHost)/api/v1/shell-app/$Id/version"
                    Method          = "POST"
                    Headers         = @{
                        "accept"        = "application/json"
                        "Authorization" = "Bearer $($script:Token.access_token)"
                    }
                    Body            = $DefinitionJson
                    ContentType     = "application/json"
                    UseBasicParsing = $true
                }
                $Result = Invoke-RestMethod @params
                if ($Result.job.status -eq "Completed") {
                    Write-Host -ForegroundColor "Green" "Shell App version created successfully. Id: $($Result.job.id)"
                }
                else {
                    Write-Host -ForegroundColor "Red" "Failed to create Shell App version. Status: $($Result.job.status)"
                }
            }
        }
        catch {
            $lineNumber = $_.InvocationInfo.ScriptLineNumber
            $scriptName = $_.InvocationInfo.ScriptName
            $errorMsg = $_.Exception.Message
            Write-Error -Message "Error on line $lineNumber in ${scriptName}: $errorMsg"
        }
    }
}
