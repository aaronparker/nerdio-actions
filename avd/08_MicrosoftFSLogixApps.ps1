#description: Installs the latest Microsoft FSLogix Apps agent
#execution mode: Combined
#tags: Evergreen, FSLogix
#Requires -Modules Evergreen
<#
    .SYNOPSIS
        Install evergreen core applications.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\Apps\Microsoft\FSLogix"
)


#region Script logic
# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null
Write-Host "Microsoft FSLogix Apps agent"

# Download
$App = Get-EvergreenApp -Name "MicrosoftFSLogixApps" | Where-Object { $_.Channel -eq "Production" } | Select-Object -First 1
Write-Host "Microsoft FSLogix Apps agent: $($App.Version)."
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

# Unpack
try {
    Write-Host "Unpacking: $($OutFile.FullName)."
    Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force
}
catch {
    Write-Host "ERR:: Failed to unpack: $($OutFile.FullName)."
}

# Install
foreach ($file in "FSLogixAppsSetup.exe", "FSLogixAppsRuleEditorSetup.exe") {
    $Installers = Get-ChildItem -Path $Path -Recurse -Include $file | Where-Object { $_.Directory -match "x64" }
    foreach ($installer in $Installers) {
        Write-Host "Installing: $($installer.FullName)."
        $params = @{
            FilePath     = $installer.FullName
            ArgumentList = "/install /quiet /norestart"
            NoNewWindow  = $True
            Wait         = $True
            PassThru     = $True
        }
        $result = Start-Process @params
        $Output = [PSCustomObject] @{
            Path     = $OutFile.FullName
            ExitCode = $result.ExitCode
        }
        Write-Host -InputObject $Output
    }
}

Write-Host "Complete: Microsoft FSLogix Apps."
#endregion
