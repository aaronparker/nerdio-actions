#description: Downloads Citrix Optimizer and optimises the OS
#execution mode: Combined
#tags: Image, Optimise
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Citrix\Optimizer"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Get the Citrix Optimizer template
switch -Regex ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption) {
    #region Windows Server
    "Microsoft Windows Server*" {
        #$OptimizerTemplate = ""
        exit 0
        break
    }
    #endregion

    #region Windows 11
    "Microsoft Windows 11 Enterprise*|Microsoft Windows 11 Pro*" {
        $OptimizerTemplate = "Citrix_Windows_11_2009.xml"
        break
    }
    #endregion

    #region Windows 10
    "Microsoft Windows 10 Enterprise*|Microsoft Windows 10 Pro*" {
        $OptimizerTemplate = "Citrix_Windows_10_2009.xml"
        break
    }
    #endregion

    default {
        $OptimizerTemplate = "Citrix_Windows_11_2009.xml"
    }
}

try {
    # Download Citrix Optimizer
    $App = [PSCustomObject]@{
        Version = "3.1.0.3"
        URI     = "https://github.com/aaronparker/packer/raw/main/build/tools/CitrixOptimizerTool.zip"
    }
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    # Run Citrix Optimizer
    Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force
    $Template = Get-ChildItem -Path $Path -Recurse -Filter $OptimizerTemplate
    $OptimizerBin = Get-ChildItem -Path $Path -Recurse -Filter "CtxOptimizerEngine.ps1"
    Push-Location -Path $OptimizerBin.Directory
    $params = @{
        Source          = $Template.FullName
        Mode            = "Execute"
        OutputLogFolder = "$env:ProgramData\Evergreen\Logs"
        OutputHtml      = "$env:SystemRoot\Temp\CitrixOptimizer.html"
        Verbose         = $False
    }
    & $OptimizerBin.FullName @params 2> $Null
    Pop-Location
}
catch {
    throw $_
}
