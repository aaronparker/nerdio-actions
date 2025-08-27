# Import the required module; Read environment variables and credentials
if ($IsWindows) {
    Import-Module -Name "Z:\projects\nerdio-actions\shell-apps\NerdioShellApps.psm1" -Force
    $EnvironmentFile = "Z:\projects\nerdio-actions\api\environment.json"
    $CredentialsFile = "Z:\projects\nerdio-actions\api\creds.json"
    $Path = "Z:\projects\nerdio-actions\shell-apps"
}
else {
    Import-Module -Name "/Users/aaron/projects/nerdio-actions/shell-apps/NerdioShellApps.psm1" -Force
    $EnvironmentFile = "/Users/aaron/projects/nerdio-actions/api/environment.json"
    $CredentialsFile = "/Users/aaron/projects/nerdio-actions/api/creds.json"
    $Path = "/Users/aaron/projects/nerdio-actions/shell-apps"
}

$Env = Get-Content -Path $EnvironmentFile | ConvertFrom-Json
$Creds = Get-Content -Path $CredentialsFile | ConvertFrom-Json
$params = @{
    ClientId           = $Creds.ClientId
    ClientSecret       = $Creds.ClientSecret
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
if ($null -eq (Get-AzContext | Where-Object { $_.Subscription.Id -eq $Creds.SubscriptionId })) {
    Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Authenticate to Azure"
    Connect-AzAccount -UseDeviceAuthentication -TenantId $Creds.tenantId -Subscription $Creds.subscriptionId
}

# Read the app definitions and create Shell Apps
$Paths = Get-ChildItem -Path $Path -Include "Definition.json" -Recurse | ForEach-Object { $_ | Select-Object -ExpandProperty "DirectoryName" }
foreach ($Path in $Paths) {
    $Def = Get-ShellAppDefinition -Path $Path
    $App = Get-AppMetadata -Definition $Def
    $ShellApp = Get-ShellApp | ForEach-Object {
        $_ | Where-Object { $_.name -eq $Def.name }
    }
    if ($null -eq $ShellApp) {
        Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Importing: $($Def.name)"
        New-ShellApp -Definition $Def -AppMetadata $App
    }
    else {
        Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Updating Shell App: $($Def.name)"
        Update-ShellApp -Id $ShellApp.Id -Definition $Def
        $ExistingVersions = Get-ShellAppVersion -Id $ShellApp.Id | ForEach-Object {
            $_ | Where-Object { $_.name -eq $App.Version }
        }
        if ($null -eq $ExistingVersions -or [System.Version]$ExistingVersions.name -lt [System.Version]$App.Version) {
            Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Updating with new version: $($Def.name)"
            New-ShellAppVersion -Id $ShellApp.Id -AppDetail $App
        }
        else {
            Write-Information -MessageData "$($PSStyle.Foreground.Yellow)Shell app version exists: '$($Def.name) $($App.Version)'. No action taken."
        }
    }
}

# Export the list of Shell Apps, showing the latest version for each app
Get-ShellApp | ForEach-Object {
    $ExistingVersions = Get-ShellAppVersion -Id $_.id | `
        Where-Object { $_.isPreview -eq $false } | `
        Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true }
    [PSCustomObject]@{
        publisher     = $_.publisher
        name          = $_.name
        versionCount  = $ExistingVersions | Measure-Object | Select-Object -ExpandProperty "Count"
        latestVersion = ($ExistingVersions | Select-Object -First 1).name
        createdAt     = $_.createdAt
        fileUnzip      = $_.fileUnzip
        isPublic      = $_.isPublic
        id            = $_.id
    }
} | Format-Table -AutoSize

# Create an App Group with the Shell Apps
$AppGroupName = "All Shell Apps"
$ShellApps = Get-ShellApp
$params = @{
    Name    = $AppGroupName
    Payload = (New-AppGroupPayload -RepoId (Get-ShellAppsRepositoryId) -ShellApp $ShellApps)
}
New-AppGroup @params

# Update the Shell App group to include all Shell Apps
$AppGroup = Get-AppGroup | Where-Object { $_.Name -eq $AppGroupName }
$ShellApps = Get-ShellApp
$ShellAppsRepoId = Get-ShellAppsRepositoryId
if ($ShellApps.Name.Count -gt $AppGroup.items.cachedName.Count) {
    $Payload = $ShellApps.Name | Where-Object { $_ -notin $AppGroup.items.cachedName } | ForEach-Object {
        $Name = $_
        $ShellApp = $ShellApps | Where-Object { $_.name -eq $Name }
        New-AppGroupPayload -RepoId $ShellAppsRepoId -ShellApp $ShellApp
    }
    $Apps = [System.Collections.ArrayList]@()
    $AppGroup.items | ForEach-Object { $Apps.Add($_) | Out-Null }
    $Payload | ForEach-Object { $Apps.Add($_) | Out-Null }
    Update-AppGroup -Id $AppGroup.id -Name $AppGroup.Name -Payload $Apps
}

# Remove the latest version of each Shell App if there are more than 2 versions
$KeepCount = 2
Get-ShellApp | ForEach-Object {
    $ExistingVersions = Get-ShellAppVersion -Id $_.id | `
        Where-Object { $_.isPreview -eq $false } | `
        Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true }
    if ($ExistingVersions.Count -gt $KeepCount) {
        $VersionsToRemove = $ExistingVersions | Select-Object -Skip ($ExistingVersions.Count - $KeepCount)
        foreach ($Version in $VersionsToRemove) {
            Write-Information -MessageData "$($PSStyle.Foreground.Cyan)Removing Shell App Version: $($_.name) $($Version.name)"
            $Result = Remove-ShellAppVersion -Id $_.id -Version $Version.name
            if ($Result.job.status -eq "Completed") {
                $File = $Version.file.sourceUrl -split "\?"
                $FileName = $File -split "/" | Select-Object -Last 1
                Remove-AzStorageBlob -Container $Env.containerName -Blob $FileName
            }
        }
    }
    else {
        Write-Information -MessageData "$($PSStyle.Foreground.Yellow)No versions to remove for Shell App: $($_.name)"
    }
}
