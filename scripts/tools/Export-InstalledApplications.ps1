<#
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs progress to the pipeline log")]
[OutputType([System.Management.Automation.PSObject])]
[CmdletBinding()]
param (
    [Parameter()]
    [System.String] $Path = "$Env:ProgramData\Evergreen\Reports\$(Get-Date -Format "yyyy-MM-dd")",

    [Parameter()]
    [System.String] $SoftwareFile = "$Path\InstalledSoftware.json",

    [Parameter()]
    [System.String] $PackagesFile = "$Path\InstalledPackages.json",

    [Parameter()]
    [System.String] $HotfixFile = "$Path\InstalledHotfixes.json",

    [Parameter()]
    [System.String] $FeaturesFile = "$Path\InstalledFeatures.json",

    [Parameter()]
    [System.String] $CapabilitiesFile = "$Path\InstalledCapabilities.json"
)

# Create the target directory
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

#region Functions
function Get-InstalledSoftware {
    [CmdletBinding()]
    param ()
    try {
        $params = @{
            PSProvider  = "Registry"
            Name        = "HKU"
            Root        = "HKEY_USERS"
            ErrorAction = "SilentlyContinue"
        }
        New-PSDrive @params | Out-Null
    }
    catch {
        throw $_.Exception.Message
    }

    $UninstallKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $UninstallKeys += Get-ChildItem -Path "HKU:" | Where-Object { $_.Name -match "S-\d-\d+-(\d+-){1,14}\d+$" } | ForEach-Object {
        "HKU:\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    }

    $Apps = @()
    foreach ($Key in $UninstallKeys) {
        try {
            $propertyNames = "DisplayName", "DisplayVersion", "Publisher", "UninstallString", "PSPath", "WindowsInstaller", "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize", "SystemComponent"
            $Apps += Get-ItemProperty -Path $Key -Name $propertyNames -ErrorAction "SilentlyContinue" | `
                . { process { if ($Null -ne $_.DisplayName) { $_ } } } | `
                Where-Object { $_.SystemComponent -ne 1 } | `
                Select-Object -Property @{n = "Name"; e = { $_.DisplayName} }, @{n = "Version"; e = { $_.DisplayVersion} }, "Publisher", "UninstallString", @{n = "RegistryPath"; e = { $_.PSPath -replace "Microsoft.PowerShell.Core\\Registry::", "" } }, "PSChildName", "WindowsInstaller", "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize" | `
                Sort-Object -Property "DisplayName", "Publisher"
        }
        catch {
            throw $_.Exception.Message
        }
    }

    Remove-PSDrive -Name "HKU" -ErrorAction "SilentlyContinue" | Out-Null
    return $Apps
}
#endregion

#region Output details of the image to JSON files that Packer can upload back to the runner
# Get the Software list; Output the installed software to the pipeline for Packer output
Write-Host "Export software list to: $SoftwareFile."
$software = Get-InstalledSoftware | Sort-Object -Property "Publisher", "Version"
$software | ConvertTo-Json | Out-File -FilePath $SoftwareFile -Force -Encoding "Utf8"

# Get the installed packages
Write-Host "Export packages list to: $PackagesFile."
$packages = Get-ProvisionedAppPackage -Online | Select-Object -Property "DisplayName", "Version"
if ($Null -ne $packages) { $packages | ConvertTo-Json | Out-File -FilePath $PackagesFile -Force -Encoding "Utf8" }

# Get the installed hotfixes
Write-Host "Export hotfix list to: $HotfixFile."
$hotfixes = Get-Hotfix | Select-Object -Property "Description", "HotFixID", "Caption" | Sort-Object -Property "HotFixID"
$hotfixes | ConvertTo-Json | Out-File -FilePath $HotfixFile -Force -Encoding "Utf8"

# Get installed features
Write-Host "Export features list to: $FeaturesFile."
$features = Get-WindowsOptionalFeature -Online | Where-Object { $_.State -eq "Enabled" } | `
    Select-Object -Property "FeatureName", "State" | Sort-Object -Property "FeatureName" -Descending
$features | ConvertTo-Json | Out-File -FilePath $FeaturesFile -Force -Encoding "Utf8"

# Get installed capabilities
Write-Host "Export capabilities list to: $CapabilitiesFile."
$capabilities = Get-WindowsCapability -Online | Where-Object { $_.State -eq "Installed" } | `
    Select-Object -Property "Name", "State" | Sort-Object -Property "Name" -Descending
$capabilities | ConvertTo-Json | Out-File -FilePath $CapabilitiesFile -Force -Encoding "Utf8"
#endregion
