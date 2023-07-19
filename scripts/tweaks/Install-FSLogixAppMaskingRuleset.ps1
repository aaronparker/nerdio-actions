#description: Downloads and installs an FSLogix App Masking ruleset
#execution mode: Combined
#tags: FSLogix
[System.String] $Path = "$Env:ProgramFiles\FSLogix\Apps\Rules"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Nerdio\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    $params = @{
        Uri             = $SecureVars.AppMaskingRuleset
        OutFile         = Join-Path -Path $Path -ChildPath $(Split-Path -Path $SecureVars.AppMaskingRuleset -Leaf)
        UseBasicParsing = $true
        ErrorAction     = "Stop"
    }
    Invoke-WebRequest @params

    $params = @{
        Path            = $(Join-Path -Path $Path -ChildPath $(Split-Path -Path $SecureVars.AppMaskingRuleset -Leaf))
        DestinationPath = $Path
        Force           = $true
    }
    Expand-Archive @params

    Remove-Item -Path $(Join-Path -Path $Path -ChildPath $(Split-Path -Path $SecureVars.AppMaskingRuleset -Leaf)) -Force -ErrorAction "SilentlyContinue"
}
catch {
    throw $_
}
