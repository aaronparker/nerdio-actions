#Requires -Module Az.Accounts, Az.Storage, Evergreen
<#
    Automate the import of a Nerdio Manager Shell App
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "", Justification = "Credential are protected locally.")]
param (
    [Parameter(Mandatory = $false)]
    [System.String] $EnvironmentFile = "/Users/aaron/projects/nerdio-actions/api/environment.json",

    [Parameter(Mandatory = $false)]
    [System.String] $CredentialsFile = "/Users/aaron/projects/nerdio-actions/api/creds.json",

    [Parameter(Mandatory = $false)]
    [System.String] $TempPath = "/Users/aaron/Temp/shell-apps",
    
    [Parameter(Mandatory = $false)]
    [System.String] $AppPath = "/Users/aaron/projects/nerdio-actions/shell-apps/Microsoft/VisualStudioCode"
)

# Read environment variables and credentials
$ErrorActionPreference = "Stop"
$env = Get-Content -Path $EnvironmentFile | ConvertFrom-Json
$creds = Get-Content -Path $CredentialsFile | ConvertFrom-Json

# Create new Shell App definition
$Definition = Get-Content -Path "$AppPath/Definition.json" | ConvertFrom-Json
$InstallScript = Get-Content -Path "$AppPath/Install.ps1" -Raw
$UninstallScript = Get-Content -Path "$AppPath/Uninstall.ps1" -Raw
$DetectScript = Get-Content -Path "$AppPath/Detect.ps1" -Raw

# Get the application details via Evergreen and download
Write-Host -ForegroundColor "Cyan" "Query Evergreen: $($Definition.source.app)"
Write-Host -ForegroundColor "Cyan" "Filter: $($Definition.source.filter)"
$App = Get-EvergreenApp -Name $Definition.source.app | Where-Object { Invoke-Expression "$($Definition.source.filter)" }
Write-Host -ForegroundColor "Cyan" "Found version $($App.Version)"
New-Item -Path $TempPath -ItemType "Directory" -Force | Out-Null
$File = $App | Save-EvergreenApp -LiteralPath $TempPath
Write-Host -ForegroundColor "Cyan" "Downloaded file: $($File.FullName)"

# Authenticate to Azure (manual authentication - update in a pipeline to use a managed identity)
if ($null -eq (Get-AzContext | Where-Object { $_.Subscription.Id -eq $creds.SubscriptionId })) {
    Write-Host -ForegroundColor "Cyan" "Authenticate to Azure"
    Connect-AzAccount -UseDeviceAuthentication -TenantId $creds.tenantId -Subscription $creds.subscriptionId
}

# Get storage account key; Create storage context
Write-Host -ForegroundColor "Cyan" "Get storage acccount key from: $($env.resourceGroupName) / $($env.storageAccountName)"
$StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $env.resourceGroupName -Name $env.storageAccountName)[0].Value
$Context = New-AzStorageContext -StorageAccountName $env.storageAccountName -StorageAccountKey $StorageAccountKey

# Upload file to blob container
$BlobName = "$(New-Guid)-$(Split-Path -Path $File.FullName -Leaf)"
$BlobFile = Set-AzStorageBlobContent -File $File.FullName -Container $env.containerName -Blob $BlobName -Context $Context
if ($null -eq $BlobFile.ICloudBlob.Uri.AbsoluteUri) {
    Write-Error -Message "Failed to upload blob file to storage account."
    exit 1
}
else {
    Write-Host -ForegroundColor "Cyan" "Uploaded file to blob: $($BlobFile.ICloudBlob.Uri.AbsoluteUri)"
}

# Update the app definition
$Definition.detectScript = $DetectScript
$Definition.installScript = $InstallScript
$Definition.uninstallScript = $UninstallScript
if ($File.FullName -match "\.zip$") {
    $Definition.fileUnzip = $true
}
$Definition.versions[0].name = $App.Version
$Definition.versions[0].file.sourceUrl = $BlobFile.ICloudBlob.Uri.AbsoluteUri
$Definition.versions[0].file.sha256 = $(if ($null -eq $App.Sha256) { (Get-FileHash -Path $File.FullName -Algorithm "SHA256").Hash } else { $App.Sha256 })
$DefinitionJson = $Definition | Select-Object -ExcludeProperty "source" | ConvertTo-Json -Depth 10

# Authenticate to Nerdio Manager
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
    ErrorAction     = "Stop"
}
$Token = Invoke-RestMethod @params
Write-Host -ForegroundColor "Cyan" "Authenticated to Nerdio Manager."

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
        ErrorAction     = "Stop"
    }
    $Result = Invoke-RestMethod @params
    if ($Result.job.status -eq "Completed") {
        Write-Host -ForegroundColor "Green" "Shell App created successfully. Id: $($Result.job.id)"
    }
    else {
        Write-Host -ForegroundColor "Red" "Failed to create Shell App. Status: $($Result.job.status)"
    }
}
