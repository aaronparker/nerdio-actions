function Get-InstalledSoftware {
    $PropertyNames = "DisplayName", "DisplayVersion", "Publisher", "UninstallString", "PSPath", "WindowsInstaller",
    "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize", "SystemComponent"
    ("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*") | `
        ForEach-Object {
        Get-ItemProperty -Path $_ -Name $PropertyNames -ErrorAction "SilentlyContinue" | `
            . { process { if ($null -ne $_.DisplayName) { $_ } } } | `
            Select-Object -Property @{n = "Name"; e = { $_.DisplayName } }, @{n = "Version"; e = { $_.DisplayVersion } }, "Publisher",
        "UninstallString", @{n = "RegistryPath"; e = { $_.PSPath -replace "Microsoft.PowerShell.Core\\Registry::", "" } },
        "PSChildName", "WindowsInstaller", "InstallDate", "InstallSource", "HelpLink", "Language", "EstimatedSize" | `
            Sort-Object -Property "Name", "Publisher"
    }
}

function ConvertTo-UninstallCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String]$UninstallString
    )
    begin {
        $regex = '(?i)"?([A-Z]:\\[^"]*?\.exe|[A-Za-z0-9._-]+\.exe)"?\s*((?:\S+\s*)*)'
    }
    process {
        if ($UninstallString -match $regex) {
            $Exe = $Matches[1]
            $Arguments = $Matches[2]
            [PSCustomObject]@{
                FilePath     = if ($Exe -match "msiexec.exe") { "$Env:SystemRoot\System32\msiexec.exe" } else { $Exe }
                ArgumentList = ($Arguments -replace '\s+', ' ').Trim()
            }
        }
        else {
            return $null
        }
    }
}

$Uninstall = Get-InstalledSoftware | Where-Object { $_.Name -match "Microsoft Edge WebView2 Runtime" } | ConvertTo-UninstallCommand
$params = @{
    FilePath     = $Uninstall.FilePath
    ArgumentList = "$($Uninstall.ArgumentList) --force-uninstall"
    Wait         = $true
    PassThru     = $true
    NoNewWindow  = $true
    ErrorAction  = "Stop"
}
$result = Start-Process @params
$Context.Log("Uninstall complete. Return code: $($result.ExitCode)")
