<#
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs progress to the pipeline log")]
[OutputType([System.Management.Automation.PSObject])]
[CmdletBinding()]
param ()

#region Functions
function Get-InstalledSoftware {
    [OutputType([System.Object[]])]
    [CmdletBinding()]
    param ()
    try {
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
            throw $_
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
                    . { process { if ($null -ne $_.DisplayName) { $_ } } } | `
                    Where-Object { $_.SystemComponent -ne 1 } | `
                    Select-Object -Property @{n = "Name"; e = { $_.DisplayName } }, @{n = "Version"; e = { $_.DisplayVersion } }, "Publisher", "UninstallString", @{n = "RegistryPath"; e = { $_.PSPath -replace "Microsoft.PowerShell.Core\\Registry::", "" } }, "PSChildName", "WindowsInstaller", "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize" | `
                    Sort-Object -Property "DisplayName", "Publisher"
            }
            catch {
                throw $_
            }
        }
        return $Apps
    }
    catch {
        throw $_
    }
    finally {
        Remove-PSDrive -Name "HKU" -ErrorAction "Ignore" | Out-Null
    }
}
#endregion

# Get the Software list; Output the installed software to the pipeline
Write-Output -InputObject (Get-InstalledSoftware | Sort-Object -Property "Name" | Format-Table -AutoSize)
