#description: Installs the latest PDFForge PDFCreator
#execution mode: Combined
#tags: Evergreen, PDFForge, PDFCreator, PDF
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\PDFForge\PDFCreator"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$env:ProgramData\NerdioManager\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "PDFForgePDFCreator" | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = "/VerySilent /Lang=en /NoIcons /COMPONENTS=None"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $false
    }
    $result = Start-Process @params
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:Public\Desktop\PDF Architect 9.lnk",
    "$Env:Public\Desktop\PDFCreator.lnk",
    "$Env:ProgramFiles\PDFCreator\PDF Architect\architect-setup.exe")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
