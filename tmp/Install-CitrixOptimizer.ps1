#description: Downloads Citrix Optimizer and optimises the OS
#execution mode: Combined
#tags: Image, Optimise
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Citrix\Optimizer"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

#region Read variables list
# Get the Citrix Optimizer template
if ([System.String]::IsNullOrEmpty($SecureVars.VariablesList)) {
    switch -Regex ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption) {
        #region Windows Server
        "Microsoft Windows Server 2022*" {
            $OptimizerTemplate = "Citrix_Windows_Server_2022_2009.xml"
            break
        }
    
        "Microsoft Windows Server 2019*" {
            $OptimizerTemplate = "Citrix_Windows_Server_2019_1809.xml"
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
}
else {
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        $params = @{
            Uri             = $SecureVars.VariablesList
            UseBasicParsing = $true
            ErrorAction     = "Stop"
        }
        $Variables = Invoke-RestMethod @params
        [System.String] $CitrixOptimizerUrl = $Variables.$AzureRegionName.CitrixOptimizer
        $params = @{
            URI             = $Variables.$AzureRegionName.CitrixOptimizerTemplate
            OutFile         = "$Path\$(Split-Path -Path $Variables.$AzureRegionName.CitrixOptimizerTemplate -Leaf).xml"
            UseBasicParsing = $true
            ErrorAction     = "Stop"
        }
        Invoke-WebRequest @params
        $OptimizerTemplate = "$Path\$(Split-Path -Path $Variables.$AzureRegionName.CitrixOptimizerTemplate -Leaf).xml"
    }
    catch {
        throw $_
    }
}
#endregion

try {
    # Download Citrix Optimizer, specify a secure variable named CitrixOptimizerUrl to pass a custom URL
    $App = [PSCustomObject]@{
        Version = "3.1.0.3"
        URI     = $CitrixOptimizerUrl
    }
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    # Run Citrix Optimizer
    Write-Information -MessageData ":: Download and run Citrix Optimizer" -InformationAction "Continue"
    Expand-Archive -Path $OutFile.FullName -DestinationPath $Path -Force
    $Template = Get-ChildItem -Path $Path -Recurse -Include $OptimizerTemplate
    $OptimizerBin = Get-ChildItem -Path $Path -Recurse -Include "CtxOptimizerEngine.ps1"
    Push-Location -Path $OptimizerBin.Directory
    Write-Information -MessageData ":: Using template: $($Template.FullName)" -InformationAction "Continue"
    $params = @{
        Source          = $Template.FullName
        Mode            = "Execute"
        OutputLogFolder = "$Env:ProgramData\Nerdio\Logs"
        OutputHtml      = "$Env:SystemRoot\Temp\CitrixOptimizer.html"
        Verbose         = $false
    }
    & $OptimizerBin.FullName @params *> $null
    Pop-Location
}
catch {
    throw $_
}
