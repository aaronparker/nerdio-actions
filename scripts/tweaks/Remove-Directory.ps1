#description: Removes a set of unnecessary directories
#execution mode: Combined
#tags: Cleanup

# Remove paths that we should not need to leave around in the image
if (Test-Path -Path "$Env:SystemDrive\Apps") {
    Remove-Item -Path "$Env:SystemDrive\Apps" -Recurse -Force -ErrorAction "SilentlyContinue"
}
if (Test-Path -Path "$Env:SystemDrive\DeployAgent") {
    Remove-Item -Path "$Env:SystemDrive\DeployAgent" -Recurse -Force -ErrorAction "SilentlyContinue"
}

Remove-Item -Path "$Env:SystemDrive\Users\AgentInstall.txt" -Force -Confirm:$false -ErrorAction "SilentlyContinue"
Remove-Item -Path "$Env:SystemDrive\Users\AgentBootLoaderInstall.txt" -Force -Confirm:$false -ErrorAction "SilentlyContinue"
