#description: Installs Windows Customised Defaults to customise the image and the default profile https://stealthpuppy.com/image-customise/
#execution mode: Combined
#tags: Evergreen, Customisation, Language, Image
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\image-customise"

#region Use Secure variables in Nerdio Manager to pass a JSON file with the variables list
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    [System.String] $Language = "en-AU"
    [System.String] $TimeZone = "AUS Eastern Standard Time"
    [System.String] $AppxMode = "Block"
}
else {
    $ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $params = @{
        Uri             = $SecureVars.VariablesList
        UseBasicParsing = $true
        ErrorAction     = "Stop"
    }
    $Variables = Invoke-RestMethod @params
    [System.String] $Language = $Variables.$AzureRegionName.Language
    [System.String] $TimeZone = $Variables.$AzureRegionName.TimeZone
    [System.String] $AppxMode = $Variables.$AzureRegionName.AppxMode
}
#endregion

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Write-Information -MessageData ":: Install Windows Customised Defaults" -InformationAction "Continue"
$Installer = Get-EvergreenApp -Name "stealthpuppyWindowsCustomisedDefaults" | Where-Object { $_.Type -eq "zip" } | `
    Select-Object -First 1 | `
    Save-EvergreenApp -CustomPath $Path
Expand-Archive -Path $Installer.FullName -DestinationPath $Path -Force
$InstallFile = Get-ChildItem -Path $Path -Recurse -Include "Install-Defaults.ps1"
Push-Location -Path $InstallFile.Directory
& .\Install-Defaults.ps1 -Language $Language -TimeZone $TimeZone -AppxMode $AppxMode
Pop-Location
#endregion
