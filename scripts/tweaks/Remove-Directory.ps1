<#
    Remove unneeded directories from the image
#>

# Remove paths that we should not need to leave around in the image
if (Test-Path -Path "$Env:SystemDrive\Apps") {
    Remove-Item -Path "$Env:SystemDrive\Apps" -Recurse -Force -ErrorAction "SilentlyContinue"
}
if (Test-Path -Path "$Env:SystemDrive\DeployAgent") {
    Remove-Item -Path "$Env:SystemDrive\DeployAgent" -Recurse -Force -ErrorAction "SilentlyContinue"
}
