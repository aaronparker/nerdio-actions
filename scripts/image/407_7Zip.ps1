#description: Installs the latest 7-Zip ZS 64-bit
#execution mode: Combined
#tags: Evergreen, 7-Zip
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\7ZipZS"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "7ZipZS" | Where-Object { $_.Architecture -eq "x64" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}

try {
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = "/S"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    Write-Information -MessageData ":: Install exit code: $($result.ExitCode)" -InformationAction "Continue"
}
catch {
    throw $_.Exception.Message
}

# Add registry entries for additional file types
@"
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\.7z]
@="7-Zip-Zstandard.7z"

[HKEY_CLASSES_ROOT\7-Zip-Zstandard.7z]
@="7z Archive"

[HKEY_CLASSES_ROOT\7-Zip-Zstandard.7z\DefaultIcon]
@="C:\\Program Files\\7-Zip-Zstandard\\7z.dll,0"

[HKEY_CLASSES_ROOT\7-Zip-Zstandard.7z\shell]
@=""

[HKEY_CLASSES_ROOT\7-Zip-Zstandard.7z\shell\open]
@=""

[HKEY_CLASSES_ROOT\7-Zip-Zstandard.7z\shell\open\command]
@="\"C:\\Program Files\\7-Zip-Zstandard\\7zFM.exe\" \"%1\""

[HKEY_CLASSES_ROOT\7-Zip-Zstandard.rar]
@="rar Archive"

[HKEY_CLASSES_ROOT\7-Zip-Zstandard.rar\DefaultIcon]
@="C:\\Program Files\\7-Zip-Zstandard\\7z.dll,3"

[HKEY_CLASSES_ROOT\7-Zip-Zstandard.rar\shell]
@=""

[HKEY_CLASSES_ROOT\7-Zip-Zstandard.rar\shell\open]
@=""

[HKEY_CLASSES_ROOT\7-Zip-Zstandard.rar\shell\open\command]
@="\"C:\\Program Files\\7-Zip-Zstandard\\7zFM.exe\" \"%1\""

[HKEY_CLASSES_ROOT\7-Zip-Zstandard.zip]
@="zip Archive"

[HKEY_CLASSES_ROOT\7-Zip-Zstandard.zip\DefaultIcon]
@="C:\\Program Files\\7-Zip-Zstandard\\7z.dll,1"

[HKEY_CLASSES_ROOT\7-Zip-Zstandard.zip\shell]
@=""

[HKEY_CLASSES_ROOT\7-Zip-Zstandard.zip\shell\open]
@=""

[HKEY_CLASSES_ROOT\7-Zip-Zstandard.zip\shell\open\command]
@="\"C:\\Program Files\\7-Zip-Zstandard\\7zFM.exe\" \"%1\""

[HKEY_CLASSES_ROOT\.rar]
@="7-Zip-Zstandard.rar"

[HKEY_CLASSES_ROOT\.zip]
@="7-Zip-Zstandard.zip"
"@ | Out-File -FilePath "$Path\FileTypes.reg" -Encoding "bigendianunicode" -Force
if (Test-Path -Path "$Path\FileTypes.reg") { & "$Env:SystemRoot\System32\reg.exe" import "$Path\FileTypes.reg" /reg:64 }
#endregion
