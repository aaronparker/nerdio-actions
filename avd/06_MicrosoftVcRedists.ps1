#description: Installs the supported Microsoft Visual C++ Redistributables
#execution mode: Combined
#tags: VcRedist
#Requires -Modules VcRedist
<#
    .SYNOPSIS
        Install evergreen core applications.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\Apps\Microsoft\VcRedist"
)

#region Script logic

# Run tasks/install apps
Write-Host "Microsoft Visual C++ Redistributables"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

Write-Host "Downloading Microsoft Visual C++ Redistributables"
Save-VcRedist -VcList (Get-VcList) -Path $Path > $Null

Write-Host "Installing Microsoft Visual C++ Redistributables"
Install-VcRedist -VcList (Get-VcList) -Path $Path -Silent | Out-Null
#endregion
