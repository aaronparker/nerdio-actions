$Context.Log("Installing Microsoft Windows App")
$params = @{
    PackagePath = $Context.GetAttachedBinary()
    Online      = $true
    SkipLicense = $true
    ErrorAction = "Stop"
}
Add-AppxProvisionedPackage @params
$Context.Log("Install complete")
