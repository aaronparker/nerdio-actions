#description: Sets a tag for Microsoft Defender for Endpoint
#execution mode: Combined
#tags: MDE

# https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/machine-tags?view=o365-worldwide

# Set a tag value
if ($null -eq $SecureVars.MdeTag) {
    $TagValue = "AVD"
}
else {
    $TagValue = $SecureVars.MdeTag
}

# Add the tag value to the registry
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection\DeviceTagging" /v "Group" /t "REG_SZ" /d $TagValue /f | Out-Null
