#description: Removes a set of unnecessary directories
#execution mode: Combined
#tags: Cleanup

# Remove paths that we should not need to leave around in the image
# Remove paths that we should not need to leave around in the image
Remove-Item -Path "$Env:SystemDrive\Apps" -Recurse -Force -ErrorAction "SilentlyContinue"
Remove-Item -Path "$Env:SystemDrive\DeployAgent" -Recurse -Force -ErrorAction "SilentlyContinue"
Remove-Item -Path "$Env:SystemDrive\Users\AgentInstall.txt" -Force -Confirm:$false -ErrorAction "SilentlyContinue"
Remove-Item -Path "$Env:SystemDrive\Users\AgentBootLoaderInstall.txt" -Force -Confirm:$false -ErrorAction "SilentlyContinue"
Remove-Item -Path "$Env:Public\Desktop\*.lnk" -Force -Confirm:$false -ErrorAction "SilentlyContinue"
