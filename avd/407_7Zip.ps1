#description: Installs the latest 7-Zip 64-bit
#execution mode: Combined
#tags: Evergreen, 7-Zip
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\7Zip"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$env:ProgramData\NerdioManager\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "7Zip" | Where-Object { $_.Architecture -eq "x64" -and $_.Type -eq "msi" } | Select-Object -First 1
    #$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
    $OutFile = Join-Path -Path $Path -ChildPath $(Split-Path -Path $App.URI -Leaf)
    Invoke-WebRequest -Uri $App.URI -OutFile $OutFile -UseBasicParsing
}
catch {
    throw $_
}

try {
    $params = @{
        FilePath     = "$env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($OutFile.FullName)`" ALLUSERS=1 /quiet /log `"$env:ProgramData\NerdioManager\Logs\7Zip.log`""
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $false
    }
    $result = Start-Process @params
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}
#endregion
