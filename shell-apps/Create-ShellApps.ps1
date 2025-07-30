Import-Module -Name "./NerdioShellApps.psm1" -Force

# Read environment variables and credentials
$EnvironmentFile = "/Users/aaron/projects/nerdio-actions/api/environment.json"
$CredentialsFile = "/Users/aaron/projects/nerdio-actions/api/creds.json"
$Env = Get-Content -Path $EnvironmentFile | ConvertFrom-Json
$Creds = Get-Content -Path $CredentialsFile | ConvertFrom-Json
$params = @{
    ClientId           = $Creds.ClientId
    ClientSecret       = (ConvertTo-SecureString -String $Creds.ClientSecret -AsPlainText -Force)
    TenantId           = $Creds.TenantId
    ApiScope           = $Creds.ApiScope
    SubscriptionId     = $Creds.SubscriptionId
    OAuthToken         = $Creds.OAuthToken
    ResourceGroupName  = $Env.resourceGroupName
    StorageAccountName = $Env.storageAccountName
    ContainerName      = $Env.containerName
    NmeHost            = $Env.nmeHost
}
Set-NmeCredentials @params
Connect-Nme

# Authenticate to Azure (manual authentication - update in a pipeline to use a managed identity)
$Creds = Get-Content -Path "/Users/aaron/projects/nerdio-actions/api/creds.json" | ConvertFrom-Json
if ($null -eq (Get-AzContext | Where-Object { $_.Subscription.Id -eq $Creds.SubscriptionId })) {
    Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Authenticate to Azure"
    Connect-AzAccount -UseDeviceAuthentication -TenantId $Creds.tenantId -Subscription $Creds.subscriptionId
}

$Path = "/Users/aaron/projects/nerdio-actions/shell-apps"
$Paths = Get-ChildItem -Path $Path -Include "Definition.json" -Recurse | ForEach-Object { $_ | Select-Object -ExpandProperty "DirectoryName" }

foreach ($Path in $Paths) {
    $Def = Get-ShellAppDefinition -Path $Path
    $App = Get-EvergreenAppDetail -Definition $Def
    $ShellApp = Get-ShellApp | ForEach-Object {
        $_.items | Where-Object { $_.name -eq $Def.name }
    }
    if ($null -eq $ShellApp) {
        Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Importing: $($Def.name)"
        New-ShellApp -Definition $Def -AppDetail $App
    }
    else {
        $ExistingVersions = Get-ShellAppVersion -Id $ShellApp.Id | ForEach-Object {
            $_.items | Where-Object { $_.name -eq $App.Version }
        }
        if ($null -eq $ExistingVersions -or [System.Version]$ExistingVersions.name -lt [System.Version]$App.Version) {
            New-ShellAppVersion -Id $ShellApp.Id -AppDetail $App
        }
        else {
            Write-Information -MessageData "$($PSStyle.Foreground.Yellow)Shell app version exists: '$($Def.name) $($App.Version)'. No action taken."
        }
    }
}

# Export the list of Shell Apps, showing the latest version for each app
(Get-ShellApp).items | ForEach-Object {
    [PSCustomObject]@{
        publisher     = $_.publisher
        name          = $_.name
        latestVersion = ((Get-ShellAppVersion -Id $_.id).items | `
                Where-Object { $_.isPreview -eq $false } | `
                Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | `
                Select-Object -First 1).name
        createdAt     = $_.createdAt
        fileUnzip      = $_.fileUnzip
        isPublic      = $_.isPublic
        id            = $_.id
    }
} | Format-Table -AutoSize
