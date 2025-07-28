#Requires -Module Az.Accounts, Az.Storage, Evergreen
<#
    Automate the import of a Nerdio Manager Shell App
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "", Justification = "Credential are protected locally.")]
param (
    [Parameter(Mandatory = $false)]
    [System.String[]] $AppPath = "/Users/aaron/projects/nerdio-actions/shell-apps/Microsoft/VisualStudioCode",

    [Parameter(Mandatory = $false)]
    [System.String] $EnvironmentFile = "/Users/aaron/projects/nerdio-actions/api/environment.json",

    [Parameter(Mandatory = $false)]
    [System.String] $CredentialsFile = "/Users/aaron/projects/nerdio-actions/api/creds.json",

    [Parameter(Mandatory = $false)]
    [System.String] $TempPath = "/Users/aaron/Temp/shell-apps",

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter] $UseRemoteUrl
)

begin {
    #functions
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

    # Read environment variables and credentials
    $ErrorActionPreference = "Stop"
    $env = Get-Content -Path $EnvironmentFile | ConvertFrom-Json
    $creds = Get-Content -Path $CredentialsFile | ConvertFrom-Json

    # Authenticate to Azure (manual authentication - update in a pipeline to use a managed identity)
    if ($null -eq (Get-AzContext | Where-Object { $_.Subscription.Id -eq $creds.SubscriptionId })) {
        Write-Host -ForegroundColor "Cyan" "Authenticate to Azure"
        Connect-AzAccount -UseDeviceAuthentication -TenantId $creds.tenantId -Subscription $creds.subscriptionId
    }

    # Authenticate to Nerdio Manager
    try {
        $params = @{
            Uri             = "https://login.microsoftonline.com/$($creds.TenantId)/oauth2/v2.0/token"
            Body            = @{
                "grant_type"  = "client_credentials"
                scope         = $creds.ApiScope
                client_id     = $creds.ClientId
                client_secret = $creds.ClientSecret
            }
            Headers         = @{
                "Accept"        = "application/json, text/plain, */*"
                "Content-Type"  = "application/x-www-form-urlencoded"
                "Cache-Control" = "no-cache"
            }
            Method          = "POST"
            UseBasicParsing = $true
        }
        $Token = Invoke-RestMethod @params
        Write-Host -ForegroundColor "Cyan" "Authenticated to Nerdio Manager."
    }
    catch {
        throw "Failed to authenticate to Nerdio Manager: $($_.Exception.Message)"
    }
}

process {
    foreach ($Path in $AppPath) {
        if (Test-Path -Path $Path -PathType "Container") {
            Write-Host -ForegroundColor "Cyan" "Processing Shell App definition at: $Path"

            # Create new Shell App definition
            $Definition = Get-Content -Path "$Path/Definition.json" | ConvertFrom-Json
            $InstallScript = Get-Content -Path "$Path/Install.ps1" -Raw
            $UninstallScript = Get-Content -Path "$Path/Uninstall.ps1" -Raw
            $DetectScript = Get-Content -Path "$Path/Detect.ps1" -Raw

            # Get the application details via Evergreen
            Write-Host -ForegroundColor "Cyan" "Query Evergreen: $($Definition.source.app)"
            Write-Host -ForegroundColor "Cyan" "Filter: $($Definition.source.filter)"
            $App = Get-EvergreenApp -Name $Definition.source.app | Where-Object { Invoke-Expression "$($Definition.source.filter)" }
            Write-Host -ForegroundColor "Cyan" "Found version $($App.Version)"

            if ($UseRemoteUrl) {
                # Use the remote URL to get the file
                if ($null -eq $App.Sha256) {
                    $Sha256 = Get-RemoteFileHash -Url $App.URI
                }
                else {
                    $Sha256 = $App.Sha256
                }

                # Set the source URL to the remote URI
                $SourceUrl = $App.URI
            }
            else {
                # Download the application binary
                New-Item -Path $TempPath -ItemType "Directory" -Force | Out-Null
                $File = $App | Save-EvergreenApp -LiteralPath $TempPath
                Write-Host -ForegroundColor "Cyan" "Downloaded file: $($File.FullName)"

                # Determine the SHA256 hash of the file
                if ($null -eq $App.Sha256) {
                    $Sha256 = (Get-FileHash -Path $File.FullName -Algorithm "SHA256").Hash
                }
                else {
                    $Sha256 = $App.Sha256
                }

                # Get storage account key; Create storage context
                Write-Host -ForegroundColor "Cyan" "Get storage acccount key from: $($env.resourceGroupName) / $($env.storageAccountName)"
                $StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $env.resourceGroupName -Name $env.storageAccountName)[0].Value
                $Context = New-AzStorageContext -StorageAccountName $env.storageAccountName -StorageAccountKey $StorageAccountKey

                # Upload file to blob container
                # Permissions required: "Storage Blob Data Contributor"
                $BlobName = "$((New-Guid) -replace '-', '').$(Split-Path -Path $File.FullName -Leaf)"
                $params = @{
                    File      = $File.FullName
                    Container = $env.containerName
                    Blob      = $BlobName
                    Context   = $Context
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
                    Container  = $env.containerName
                    Blob       = $BlobName
                    Permission = "r"
                    ExpiryTime = (Get-Date).AddYears(10)
                    FullUri    = $true
                }
                $SasToken = New-AzStorageBlobSASToken @params

                # Determine the source URL, if a SAS token is provided, use it; otherwise, use the blob URI
                $(if ($SasToken) { $SourceUrl = $SasToken } else { $SourceUrl = $BlobFile.ICloudBlob.Uri.AbsoluteUri })
            }

            # Update the app definition
            $Definition.detectScript = $DetectScript
            $Definition.installScript = $InstallScript
            $Definition.uninstallScript = $UninstallScript
            if ($File.FullName -match "\.zip$") {
                $Definition.fileUnzip = $true
            }
            $Definition.versions[0].name = $App.Version
            $Definition.versions[0].file.sourceUrl = $SourceUrl
            $Definition.versions[0].file.sha256 = $Sha256
            $DefinitionJson = $Definition | Select-Object -ExcludeProperty "source" | ConvertTo-Json -Depth 10

            # Create the Shell App in Nerdio Manager
            if ($Token) {
                $params = @{
                    Uri             = "https://$($env.nmeHost)/api/v1/shell-app"
                    Method          = "POST"
                    Headers         = @{
                        "accept"        = "application/json"
                        "Authorization" = "Bearer $($Token.access_token)"
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
        else {
            Write-Error "Path does not exist or is not a directory: $Path"
            continue
        }
    }
}
