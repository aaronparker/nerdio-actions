#Requires -PSEdition Core
#Requires -Module Az.Accounts, Az.Storage, Evergreen, VcRedist
[CmdletBinding()]

# Configure the environment
$ProgressPreference = "SilentlyContinue"
$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"
if ([System.Enum]::IsDefined([System.Net.SecurityProtocolType], "Tls13")) {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls13
}
else {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
}

# Set up global variables for credentials and environment
$script:creds = [PSCustomObject] @{
    ClientId       = $null
    ClientSecret   = $null
    TenantId       = $null
    ApiScope       = $null
    NmeUri         = $null
    SubscriptionId = $null
    OAuthToken     = $null
}

$script:env = [PSCustomObject] @{
    resourceGroupName  = $null
    storageAccountName = $null
    containerName      = $null
    nmeHost            = $null
}

function Set-NmeCredentials {
    param (
        [Parameter(Mandatory = $true)]
        [System.String] $ClientId,

        [Parameter(Mandatory = $true)]
        [System.String] $ClientSecret,

        [Parameter(Mandatory = $true)]
        [System.String] $TenantId,

        [Parameter(Mandatory = $true)]
        [System.String] $ApiScope,

        [Parameter(Mandatory = $true)]
        [System.String] $SubscriptionId,

        [Parameter(Mandatory = $true)]
        [System.String] $OAuthToken,

        [Parameter(Mandatory = $true)]
        [System.String] $ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [System.String] $StorageAccountName,

        [Parameter(Mandatory = $true)]
        [System.String] $ContainerName,

        [Parameter(Mandatory = $true)]
        [System.String] $NmeHost
    )

    $script:creds = [PSCustomObject] @{
        ClientId       = $ClientId
        ClientSecret   = $ClientSecret
        TenantId       = $TenantId
        ApiScope       = $ApiScope
        NmeUri         = $null
        SubscriptionId = $SubscriptionId
        OAuthToken     = $OAuthToken
    }

    $script:env = [PSCustomObject] @{
        resourceGroupName  = $ResourceGroupName
        storageAccountName = $StorageAccountName
        containerName      = $ContainerName
        nmeHost            = $NmeHost
    }
}

function Connect-Nme {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $PassThru
    )
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
        Write-Information -MessageData "$($PSStyle.Foreground.Green)Authenticated to Nerdio Manager."
        Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Token expires: $((Get-Date).AddSeconds($script:Token.expires_in).ToString())"
        if ($PassThru) {
            return $script:Token
        }
    }
    catch {
        throw "Failed to authenticate to Nerdio Manager: $($_.Exception.Message)"
    }
}

function Get-TempDirectory {
    switch -Regex ($PSVersionTable.OS) {
        'Windows' {
            return $env:TEMP ?? $env:TMP ?? "$env:USERPROFILE\AppData\Local\Temp"
        }
        'Darwin' {
            return $env:TMPDIR ?? '/tmp'
        }
        'Ubuntu' {
            return $env:TMPDIR ?? '/tmp'
        }
        'Linux' {
            return $env:TMPDIR ?? '/tmp'
        }
        default {
            throw "Unsupported OS: $($PSVersionTable.OS)"
        }
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
        Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Opening remote stream: $Url"
        $Stream = $WebClient.OpenRead($Url)
        if ($null -eq $Stream) {
            throw "Failed to open remote stream. Stream is null."
        }
        Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Calculating SHA256 hash."
        $hash = Get-FileHash -Algorithm "SHA256" -InputStream $Stream
        Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Hash: $($hash.Hash)"
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

function Get-AppMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [PSCustomObject] $Definition
    )
    process {
        switch ($Definition.source.type) {
            "Evergreen" {
                Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Query: Get-EvergreenApp -Name $($Definition.source.app) | Where-Object { $($Definition.source.filter) }"
                $Metadata = Get-EvergreenApp -Name $Definition.source.app | Where-Object { Invoke-Expression "$($Definition.source.filter)" }
                Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Found version: $($Metadata.Version)"
                return $Metadata
            }
            "VcRedist" {
                Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Query: Get-VcList | Where-Object { $($Definition.source.filter) }"
                $Metadata = Get-VcList | Where-Object { Invoke-Expression "$($Definition.source.filter)" }
                Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Found version: $($Metadata.Version)"
                return $Metadata
            }
            "Static" {
                if ([System.String]::IsNullOrEmpty($Definition.source.url)) {
                    # TODO - add an object that uses local file system
                    return $null
                }
                else {
                    Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Using direct source URL: $($Definition.source.url)"
                    $Metadata = [PSCustomObject] @{
                        Version = $Definition.source.version
                        URI     = $Definition.source.url
                    }
                    return $Metadata
                }
            }
        }
    }
}

function Get-ShellAppDefinition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String] $Path
    )
    process {
        if (Test-Path -Path $Path -PathType "Container") {
            Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Reading Shell App definition from: $Path"
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
        try {
            # Get existing Shell Apps
            $params = @{
                Uri             = "https://$($script:env.nmeHost)/api/v1/shell-app"
                Headers         = @{
                    "Accept"        = "application/json; utf-8"
                    "Authorization" = "Bearer $($script:Token.access_token)"
                    "Content-Type"  = "application/x-www-form-urlencoded"
                    "Cache-Control" = "no-cache"
                }
                Method          = "GET"
                UseBasicParsing = $true
            }
            $Result = Invoke-RestMethod @params
            return $Result.items
        }
        catch {
            throw $_
        }
    }
}

function Get-ShellAppVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [System.String] $Id
    )
    process {
        # Get versions of existing Shell App
        $params = @{
            Uri             = "https://$($script:env.nmeHost)/api/v1/shell-app/$Id/version"
            Headers         = @{
                "Accept"        = "application/json; utf-8"
                "Authorization" = "Bearer $($script:Token.access_token)"
                "Content-Type"  = "application/x-www-form-urlencoded"
                "Cache-Control" = "no-cache"
            }
            Method          = "GET"
            UseBasicParsing = $true
        }
        $Result = Invoke-RestMethod @params
        return $Result.items
    }
}

function New-ShellAppFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $AppMetadata,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $UseRemoteUrl,

        [Parameter(Mandatory = $false)]
        [System.String] $TempPath = (Get-TempDirectory)
    )

    if ($UseRemoteUrl) {
        # Use the remote URL to get the file. This assumes an object passed from Get-AppMetadata
        if ($null -eq $AppMetadata.Sha256) {
            $Sha256 = Get-RemoteFileHash -Url $AppMetadata.URI
        }
        else {
            Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Using provided SHA256 hash: $($AppMetadata.Sha256)"
            $Sha256 = $AppMetadata.Sha256
        }

        # Create a PSCustomObject with the file details
        $Output = [PSCustomObject] @{
            Sha256    = $Sha256
            FileType  = [System.IO.Path]::GetExtension($AppMetadata.URI).TrimStart('.')
            SourceUrl = $AppMetadata.URI
        }
        return $Output
    }
    else {
        if ([System.String]::IsNullOrEmpty($AppMetadata.URI)) {
            # Assume $AppMetadata.File is provided on the object
            try {
                $File = Get-Item -Path $AppMetadata.File
            }
            catch {
                Write-Error -Message "File not found: $($AppMetadata.File). Ensure the file exists."
                exit 1
            }
        }
        else {
            # If the URI is provided, download the file with Evergreen
            New-Item -Path $TempPath -ItemType "Directory" -Force | Out-Null
            $File = $AppMetadata | Save-EvergreenApp -LiteralPath $TempPath
            Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Downloaded file: $($File.FullName)"
        }

        # Determine the SHA256 hash of the file
        if ($null -eq $AppMetadata.Sha256) {
            $Sha256 = (Get-FileHash -Path $File.FullName -Algorithm "SHA256").Hash
        }
        else {
            $Sha256 = $AppMetadata.Sha256
        }

        # Get storage account key; Create storage context
        Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Get storage acccount key from: $($script:env.resourceGroupName) / $($script:env.storageAccountName)"
        $StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $script:env.resourceGroupName -Name $script:env.storageAccountName)[0].Value
        $Context = New-AzStorageContext -StorageAccountName $script:env.storageAccountName -StorageAccountKey $StorageAccountKey

        # Upload file to blob container
        # Permissions required: "Storage Blob Data Contributor"
        $BlobName = "$(Get-MD5Hash -InputString $Sha256).$(Split-Path -Path $File.FullName -Leaf)"
        Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Uploading file to blob: $BlobName"
        $ProgressPreference = "Continue"
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
            Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Uploaded file to blob: $($BlobFile.ICloudBlob.Uri.AbsoluteUri)"
        }

        # Get a read-only SAS token for the blob with a long expiry time
        $params = @{
            Context    = $Context
            Container  = $script:env.containerName
            Blob       = $BlobName
            Permission = "r"
            ExpiryTime = (Get-Date).AddYears(5)
            FullUri    = $true
        }
        $SasToken = New-AzStorageBlobSASToken @params

        # Determine the source URL, if a SAS token is provided, use it; otherwise, use the blob URI
        if ($SasToken) {
            Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Using SAS token for source URL."
            $SourceUrl = $SasToken
        }
        else {
            Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Using blob URI for source URL."
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
        [PSCustomObject] $AppMetadata,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $UseRemoteUrl
    )
    process {
        try {
            # Create a file object for the Shell App
            $params = @{
                AppMetadata  = $AppMetadata
                UseRemoteUrl = $UseRemoteUrl
            }
            $File = New-ShellAppFile @params

            # Update the app definition
            if ($File.FileType -eq "zip") {
                Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Using fileUnzip: true for zip files."
                $Definition.fileUnzip = $true
            }
            $Definition.versions[0].name = $AppMetadata.Version
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
                    Write-Information -MessageData "$($PSStyle.Foreground.Green)Shell App created successfully. Job Id: $($Result.job.id)"
                }
                else {
                    Write-Error -Message "Failed to create Shell App. Status: $($Result.job.status)"
                }
                return $Result
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
        [PSCustomObject] $AppMetadata,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $UseRemoteUrl
    )
    process {
        # Create the Shell App version in Nerdio Manager
        try {
            # Create a file object for the Shell App version
            $params = @{
                AppMetadata  = $AppMetadata
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
            $Definition.name = $AppMetadata.Version
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
                    Write-Information -MessageData "$($PSStyle.Foreground.Green)Shell App version created successfully. Job Id: $($Result.job.id)"
                }
                else {
                    Write-Error -Message "Failed to create Shell App version. Status: $($Result.job.status)"
                }
                return $Result
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

function Remove-ShellApp {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
        [System.String] $Id
    )
    process {
        if ($PSCmdlet.ShouldProcess("Shell App: $Id", "Remove")) {
            Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Removing Shell App Id: $Id"
            try {
                $params = @{
                    Uri             = "https://$($script:env.nmeHost)/api/v1/shell-app/$Id"
                    Headers         = @{
                        "Accept"        = "application/json; utf-8"
                        "Authorization" = "Bearer $($script:Token.access_token)"
                        "Cache-Control" = "no-cache"
                    }
                    Method          = "DELETE"
                    UseBasicParsing = $true
                }
                $Result = Invoke-RestMethod @params
                if ($Result.job.status -eq "Completed") {
                    Write-Information -MessageData "$($PSStyle.Foreground.Green)Shell App ($Id) removed successfully. Job Id: $($Result.job.id)"
                }
                elseif ($Result.job.status -eq "Pending") {
                    Write-Information -MessageData "$($PSStyle.Foreground.Yellow)Shell App ($Id) removal status: $($Result.job.status)."
                }
                elseif ($Result.job.status -eq "Failed") {
                    Write-Error -Message "Failed to remove Shell App ($Id). Status: $($Result.job.status)"
                }
                return $Result
            }
            catch {
                throw "Failed to remove Shell App: $($_.Exception.Message)"
            }
        }
    }
}

function Remove-ShellAppVersion {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
        [System.String] $Id,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
        [System.String] $Name
    )
    process {
        if ($PSCmdlet.ShouldProcess("Shell App: $Name", "Remove")) {
            Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Removing Shell App version: $Id, $Name"
            try {
                $params = @{
                    Uri             = "https://$($script:env.nmeHost)/api/v1/shell-app/$Id/version/$Name"
                    Headers         = @{
                        "Accept"        = "application/json; utf-8"
                        "Authorization" = "Bearer $($script:Token.access_token)"
                        "Cache-Control" = "no-cache"
                    }
                    Method          = "DELETE"
                    UseBasicParsing = $true
                }
                $Result = Invoke-RestMethod @params
                if ($Result.job.status -eq "Completed") {
                    Write-Information -MessageData "$($PSStyle.Foreground.Green)Shell App version ($Id, $Name) removed successfully. Job Id: $($Result.job.id)"
                }
                elseif ($Result.job.status -eq "Pending") {
                    Write-Information -MessageData "$($PSStyle.Foreground.Yellow)Shell App version ($Id, $Name) removal status: $($Result.job.status)."
                }
                elseif ($Result.job.status -eq "Failed") {
                    Write-Error -Message "Failed to remove Shell App version ($Id, $Name). Status: $($Result.job.status)"
                }
                return $Result
            }
            catch {
                throw "Failed to remove Shell App: $($_.Exception.Message)"
            }
        }
        else {
            Write-Information -MessageData "$($PSStyle.Foreground.Yellow)Skipping removal of Shell App Id: $Id with version: $Name"
            return
        }
    }
}

function Update-ShellApp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
        [System.String] $Id,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $Definition
    )
    process {
        try {
            Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Updating Shell App Id: $Id"
            $DefinitionJson = $Definition | ConvertTo-Json -Depth 10
            $params = @{
                Uri             = "https://$($script:env.nmeHost)/api/v1/shell-app/$Id"
                Method          = "PATCH"
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
                Write-Information -MessageData "$($PSStyle.Foreground.Green)Shell App updated successfully. Job Id: $($Result.job.id)"
            }
            else {
                Write-Error -Message "Failed to update Shell App. Status: $($Result.job.status)"
            }
            return $Result
        }
        catch {
            throw "Failed to update Shell App: $($_.Exception.Message)"
        }
    }
}

function Remove-NerdioManagerSecretsFromMemory {
    [CmdletBinding()]
    param ()
    process {
        if (!([System.String]::IsNullOrEmpty($script:creds.ClientSecret))) { $script:creds.ClientSecret = $null }
        if (!([System.String]::IsNullOrEmpty($script:Token.access_token))) { $script:Token.access_token = $null }
        Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Client secret and access token cleared from memory. Use 'Set-NmeCredentials' and 'Connect-Nme' to re-authenticate."
    }
}

function Get-AppGroup {
    [CmdletBinding()]
    param ()
    process {
        try {
            $params = @{
                Uri             = "https://$($script:env.nmeHost)/api/v1/app-management/app-group"
                Headers         = @{
                    "Accept"        = "application/json; utf-8"
                    "Authorization" = "Bearer $($script:Token.access_token)"
                    "Cache-Control" = "no-cache"
                }
                Method          = "GET"
                UseBasicParsing = $true
            }
            $Result = Invoke-RestMethod @params
            return $Result.items
        }
        catch {
            throw "Failed to get App Group: $($_.Exception.Message)"
        }
    }
}

function Get-UamRepository {
    [CmdletBinding()]
    param ()
    process {
        try {
            $params = @{
                Uri             = "https://$($script:env.nmeHost)/api/v1/app-management/repository"
                Headers         = @{
                    "Accept"        = "application/json; utf-8"
                    "Authorization" = "Bearer $($script:Token.access_token)"
                    "Cache-Control" = "no-cache"
                }
                Method          = "GET"
                UseBasicParsing = $true
            }
            $Result = Invoke-RestMethod @params
            return $Result
        }
        catch {
            throw "Failed to get UAM Repository: $($_.Exception.Message)"
        }
    }
}

function New-AppGroupPayload {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Int32] $RepoId,

        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [Object[]] $ShellApp
    )
    process {
        foreach ($App in $ShellApp) {
            [PSCustomObject]@{
                repoId     = $RepoId
                externalId = $App.publicId
                version    = "latest"
                cachedName = $App.name
                reboot     = $false
            }
        }
    }
}

function Get-ShellAppsRepositoryId {
    [CmdletBinding()]
    param ()
    process {
        $Id = Get-UamRepository | Where-Object { $_.type -eq "Shell" } | Select-Object -ExpandProperty "id"
        return $Id
    }
}

function New-AppGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String] $Name,

        [Parameter(Mandatory = $true)]
        [Object] $Payload
    )
    process {
        try {
            $Body = [Ordered]@{
                name  = $Name
                items = $Payload
            } | ConvertTo-Json -Depth 10
            $params = @{
                Uri             = "https://$($script:env.nmeHost)/api/v1/app-management/app-group"
                Method          = "POST"
                Headers         = @{
                    "Accept"        = "application/json; utf-8"
                    "Authorization" = "Bearer $($script:Token.access_token)"
                    "Cache-Control" = "no-cache"
                }
                Body            = $Body
                ContentType     = "application/json"
                UseBasicParsing = $true
            }
            $Result = Invoke-RestMethod @params
            return $Result
        }
        catch {
            throw "Failed to create App Group: $($_.Exception.Message)"
        }
    }
}

function Update-AppGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Int32] $Id,

        [Parameter(Mandatory = $true)]
        [System.String] $Name,

        [Parameter(Mandatory = $true)]
        [Object] $Payload
    )
    process {
        try {
            $Body = [Ordered]@{
                name  = $Name
                items = $Payload
            } | ConvertTo-Json -Depth 10
            $params = @{
                Uri             = "https://$($script:env.nmeHost)/api/v1/app-management/app-group/$Id"
                Method          = "PATCH"
                Headers         = @{
                    "Accept"        = "application/json; utf-8"
                    "Authorization" = "Bearer $($script:Token.access_token)"
                    "Cache-Control" = "no-cache"
                }
                Body            = $Body
                ContentType     = "application/json"
                UseBasicParsing = $true
            }
            $Result = Invoke-RestMethod @params
            return $Result
        }
        catch {
            throw "Failed to update App Group: $($_.Exception.Message)"
        }
    }
}

function Get-MsiVersion {
    param (
        [Parameter(Mandatory)]
        [System.String]$Path
    )
    try {
        $installer = New-Object -ComObject "WindowsInstaller.Installer"
        $database = $installer.GetType().InvokeMember("OpenDatabase", 'InvokeMethod', $null, $installer, @($Path, 0))
        $view = $database.GetType().InvokeMember("OpenView", 'InvokeMethod', $null, $database, @("SELECT `Value` FROM `Property` WHERE `Property` = 'ProductVersion'"))
        $view.GetType().InvokeMember("Execute", 'InvokeMethod', $null, $view, $null)
        $record = $view.GetType().InvokeMember("Fetch", 'InvokeMethod', $null, $view, $null)
        $version = $record.GetType().InvokeMember("StringData", 'GetProperty', $null, $record, 1)
        return $version
    }
    catch {
        throw "Failed to read MSI version: $_"
    }
}
