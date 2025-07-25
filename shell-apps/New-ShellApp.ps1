<#
    Automate the import of a Nerdio Manager Shell App
#>

# Environment variables
$Path = "/Users/aaron/projects/nerdio-actions"
$env = Get-Content -Path "$Path/shell-apps/environment.json" | ConvertFrom-Json
$creds = Get-Content -Path "$Path/api/creds.json" | ConvertFrom-Json

# Create new Shell App definition
$Definition = Get-Content -Path "$Path/shell-apps/Microsoft/VisualStudioCode/Definition.json" | ConvertFrom-Json
$InstallScript = Get-Content -Path "$Path/shell-apps/Microsoft/VisualStudioCode/Install.ps1" -Raw
$UninstallScript = Get-Content -Path "$Path/shell-apps/Microsoft/VisualStudioCode/Uninstall.ps1" -Raw
$DetectScript = Get-Content -Path "$Path/shell-apps/Microsoft/VisualStudioCode/Detect.ps1" -Raw

# Get the application details via Evergreen and download
New-Item -Path "/Users/aaron/Temp/shell-apps" -ItemType "Directory" -Force | Out-Null
Write-Host -ForegroundColor "Cyan" "Query Evergreen: $($Definition.source.app)"
Write-Host -ForegroundColor "Cyan" "Filter: $($Definition.source.filter)"
$App = Get-EvergreenApp -Name $Definition.source.app | Where-Object { Invoke-Expression "$($Definition.source.filter)" }
Write-Host -ForegroundColor "Cyan" "Found version $($App.Version)"
$File = $App | Save-EvergreenApp -LiteralPath "/Users/aaron/Temp/shell-apps"
Write-Host -ForegroundColor "Cyan" "Downloaded file: $($File.FullName)"

# Get the SHA256 hash of the file
if ($null -eq $App.Sha256) {
    $Sha256 = Get-FileHash -Path $File.FullName -Algorithm "SHA256"
}
else {
    $Sha256 = $App.Sha256
}

# Authenticate to Azure (manual authentication)
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
Write-Host -ForegroundColor "Cyan" "Uploaded file to blob: $($BlobFile.ICloudBlob.Uri.AbsoluteUri)"

# Update the app definition
$Definition.detectScript = $DetectScript
$Definition.installScript = $InstallScript
$Definition.uninstallScript = $UninstallScript
$Definition.versions[0].name = $App.Version
$Definition.versions[0].file.sourceUrl = $BlobFile.ICloudBlob.Uri.AbsoluteUri
$Definition.versions[0].file.sha256 = $Sha256
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
