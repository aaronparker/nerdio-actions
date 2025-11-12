#description: Installs the latest PDFForge PDFCreator
#execution mode: Combined
#tags: Evergreen, PDFForge, PDFCreator, PDF
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\PDFForge\PDFCreator"
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Import shared functions written to disk by 000_PrepImage.ps1
$FunctionFile = "$Env:TEMP\NerdioFunctions.psm1"
Import-Module -Name $FunctionFile -Force -ErrorAction "Stop"
Write-LogFile -Message "Functions imported from: $FunctionFile"

Write-LogFile -Message "Query Evergreen for PDFForge PDFCreator"
$App = Get-EvergreenApp -Name "PDFForgePDFCreator" | Select-Object -First 1
Write-LogFile -Message "Downloading PDFForge PDFCreator version $($App.Version) to $Path"
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -ErrorAction "Stop"

$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/VerySilent /Lang=en /NoIcons /COMPONENTS=None"
}
Start-ProcessWithLog @params

Start-Sleep -Seconds 5
$Shortcuts = @("$Env:Public\Desktop\PDF Architect 9.lnk",
    "$Env:Public\Desktop\PDFCreator.lnk",
    "$Env:ProgramFiles\PDFCreator\PDF Architect\architect-setup.exe")
Remove-Item -Path $Shortcuts -Force -ErrorAction "Ignore"
