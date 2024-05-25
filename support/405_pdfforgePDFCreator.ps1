#description: Installs the latest PDFForge PDFCreator
#execution mode: Combined
#tags: Evergreen, PDFForge, PDFCreator, PDF
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\PDFForge\PDFCreator"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

Import-Module -Name "Evergreen" -Force
$App = Get-EvergreenApp -Name "PDFForgePDFCreator" | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/VerySilent /Lang=en /NoIcons /COMPONENTS=None"
    NoNewWindow  = $true
    Wait         = $true
    PassThru     = $true
    ErrorAction  = "Stop"
}
Start-Process @params

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:Public\Desktop\PDF Architect 9.lnk",
    "$Env:Public\Desktop\PDFCreator.lnk",
    "$Env:ProgramFiles\PDFCreator\PDF Architect\architect-setup.exe")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
#endregion
