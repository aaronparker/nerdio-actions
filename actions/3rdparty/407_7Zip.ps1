<#
    .SYNOPSIS
    Installs the latest 7-Zip ZS 64-bit.

    .DESCRIPTION
    This script installs the latest version of 7-Zip ZS 64-bit.
    It creates the necessary directories, imports the Evergreen module, downloads and installs the 7-Zip ZS application,
    and adds registry entries for additional file types.

    .PARAMETER Path
    The download path for 7-Zip ZS.
#>

#description: Installs the latest 7-Zip ZS 64-bit
#execution mode: Combined
#tags: Evergreen, 7-Zip
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\7ZipZS"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

Write-LogFile -Message "Query Evergreen for 7-Zip ZS x64"
$App = Get-EvergreenApp -Name "7ZipZS" | Where-Object { $_.Architecture -eq "x64" } | Select-Object -First 1
Write-LogFile -Message "Downloading 7-Zip ZS version $($App.Version) to $Path"
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/S"
}
Start-ProcessWithLog @params

Remove-Item -Path "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip-Zstandard\7-Zip Help.lnk" -Force -ErrorAction "SilentlyContinue" | Out-Null

#region Add registry entries for additional file types
Write-LogFile -Message "Adding registry entries for additional file types for 7-Zip ZS"
# .7z
New-Item -Path "HKLM:\SOFTWARE\Classes\.7z" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.7z" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.7z\DefaultIcon" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.7z\shell" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.7z\shell\open" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.7z\shell\open\command" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\.7z' -Name '(default)' -Value '7-Zip-Zstandard.7z' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.7z' -Name '(default)' -Value '7z Archive' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.7z\DefaultIcon' -Name '(default)' -Value 'C:\Program Files\7-Zip-Zstandard\7z.dll,0' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.7z\shell' -Name '(default)' -Value '' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.7z\shell\open' -Name '(default)' -Value '' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.7z\shell\open\command' -Name '(default)' -Value '"C:\Program Files\7-Zip-Zstandard\7zFM.exe" "%1"' -PropertyType "String" -Force | Out-Null

# .z
New-Item -Path "HKLM:\SOFTWARE\Classes\.z" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.z" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.z\DefaultIcon" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.z\shell" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.z\shell\open" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.z\shell\open\command" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\.z' -Name '(default)' -Value '7-Zip-Zstandard.z' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.z' -Name '(default)' -Value 'z Archive' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.z\DefaultIcon' -Name '(default)' -Value 'C:\Program Files\7-Zip-Zstandard\7z.dll,0' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.z\shell' -Name '(default)' -Value '' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.z\shell\open' -Name '(default)' -Value '' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.z\shell\open\command' -Name '(default)' -Value '"C:\Program Files\7-Zip-Zstandard\7zFM.exe" "%1"' -PropertyType "String" -Force | Out-Null

# .rar
New-Item -Path "HKLM:\SOFTWARE\Classes\.rar" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.rar" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.rar\DefaultIcon" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.rar\shell" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.rar\shell\open" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.rar\shell\open\command" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\.rar' -Name '(default)' -Value '7-Zip-Zstandard.rar' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.rar' -Name '(default)' -Value 'rar Archive' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.rar\DefaultIcon' -Name '(default)' -Value 'C:\Program Files\7-Zip-Zstandard\7z.dll,3' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.rar\shell' -Name '(default)' -Value '' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.rar\shell\open' -Name '(default)' -Value '' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.rar\shell\open\command' -Name '(default)' -Value '"C:\Program Files\7-Zip-Zstandard\7zFM.exe" "%1"' -PropertyType "String" -Force | Out-Null

# .zip
New-Item -Path "HKLM:\SOFTWARE\Classes\.zip" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.zip" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.zip\DefaultIcon" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.zip\shell" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.zip\shell\open" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.zip\shell\open\command" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\.zip' -Name '(default)' -Value '7-Zip-Zstandard.zip' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.zip' -Name '(default)' -Value 'zip Archive' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.zip\DefaultIcon' -Name '(default)' -Value 'C:\Program Files\7-Zip-Zstandard\7z.dll,1' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.zip\shell' -Name '(default)' -Value '' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.zip\shell\open' -Name '(default)' -Value '' -PropertyType "String" -Force | Out-Null
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\7-Zip-Zstandard.zip\shell\open\command' -Name '(default)' -Value '"C:\Program Files\7-Zip-Zstandard\7zFM.exe" "%1"' -PropertyType "String" -Force | Out-Null
#endregion
