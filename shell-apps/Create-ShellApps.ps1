Import-Module -Name "./NerdioShellApps.psm1" -Force
Connect-Nme

# Authenticate to Azure (manual authentication - update in a pipeline to use a managed identity)
$creds = Get-Content -Path "/Users/aaron/projects/nerdio-actions/api/creds.json" | ConvertFrom-Json
if ($null -eq (Get-AzContext | Where-Object { $_.Subscription.Id -eq $creds.SubscriptionId })) {
    Write-Host -ForegroundColor "Cyan" "Authenticate to Azure"
    Connect-AzAccount -UseDeviceAuthentication -TenantId $creds.tenantId -Subscription $creds.subscriptionId
}

$Paths = @("/Users/aaron/projects/nerdio-actions/shell-apps/Audacity",
    "/Users/aaron/projects/nerdio-actions/shell-apps/Microsoft/AvdMultimediaRedirection",
    "/Users/aaron/projects/nerdio-actions/shell-apps/Microsoft/AvdRtcService",
    "/Users/aaron/projects/nerdio-actions/shell-apps/Microsoft/Edge",
    "/Users/aaron/projects/nerdio-actions/shell-apps/Microsoft/FSLogixApps",
    "/Users/aaron/projects/nerdio-actions/shell-apps/Microsoft/NETLTS",
    "/Users/aaron/projects/nerdio-actions/shell-apps/Microsoft/OneDrive",
    "/Users/aaron/projects/nerdio-actions/shell-apps/Microsoft/SQLServerManagementStudio",
    "/Users/aaron/projects/nerdio-actions/shell-apps/Microsoft/VisualStudioCode")
foreach ($Path in $Paths) {
    $Def = Get-ShellAppDefinition -Path $Path
    $App = Get-EvergreenAppDetail -Definition $Def
    $ShellApp = Get-ShellApp | ForEach-Object {
        $_.items | Where-Object { $_.name -eq $Def.name }
    }
    if ($null -eq $ShellApp) {
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
            Write-Host -ForegroundColor "Yellow" "Shell app $($Def.name) already exists with version $($App.Version). No action taken."
        }
    }
}
