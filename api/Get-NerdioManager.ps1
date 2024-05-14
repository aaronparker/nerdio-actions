
$creds = Get-Content -Path "./creds.json" | ConvertFrom-Json
$params = @{
    ClientId     = $creds.ClientId
    ClientSecret = $creds.ClientSecret
    TenantId     = $creds.TenantId
    ApiScope     = $creds.ApiScope
    NmeUri       = $creds.NmeUri
}
Connect-Nme @params

$params = @{
    SubscriptionId = $creds.SubscriptionId
    ResourceGroup  = "rg-AvdManagement-australiaeast"
    HostPoolName   = "vdpool-Pooled-australiaeast"
}
Get-NmeHostPool @params

$params = @{
    SubscriptionId = $creds.SubscriptionId
    ResourceGroup  = "rg-AvdManagement-australiaeast"
    HostPoolName   = "vdpool-Pooled-australiaeast"
}
Get-NmeHostPoolAutoScaleConfig @params
