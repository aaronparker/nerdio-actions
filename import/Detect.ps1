<#
.SYNOPSIS
    Detects software installation based on detection rules in JSON format.

.DESCRIPTION
    This script evaluates multiple detection rules (registry, file, MSI product code)
    and returns $true if all rules are satisfied, otherwise $false.

.PARAMETER DetectionJson
    JSON string or file path containing detection rules.

.EXAMPLE
    .\Detect-Software.ps1 -DetectionJson (Get-Content -Path "Detect.json" -Raw)
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$DetectionJson
)

function Test-RegistryDetection {
    param(
        [string]$KeyPath,
        [string]$ValueName,
        [string]$DetectionValue,
        [string]$Operator,
        [string]$DetectionType,
        [bool]$Check32BitOn64System
    )

    # Convert registry path format
    $KeyPath = $KeyPath -replace "HKEY_LOCAL_MACHINE", "HKLM:"
    $KeyPath = $KeyPath -replace "HKEY_CURRENT_USER", "HKCU:"

    if (-not (Test-Path -Path $KeyPath)) {
        return $false
    }

    try {
        $RegValue = Get-ItemProperty -Path $KeyPath -Name $ValueName -ErrorAction Stop
        $ActualValue = $RegValue.$ValueName

        if ($DetectionType -eq "version") {
            $ActualVersion = [version]$ActualValue
            $ExpectedVersion = [version]$DetectionValue

            switch ($Operator) {
                "greaterThanOrEqual" { return $ActualVersion -ge $ExpectedVersion }
                "greaterThan" { return $ActualVersion -gt $ExpectedVersion }
                "equal" { return $ActualVersion -eq $ExpectedVersion }
                "lessThan" { return $ActualVersion -lt $ExpectedVersion }
                "lessThanOrEqual" { return $ActualVersion -le $ExpectedVersion }
                "notEqual" { return $ActualVersion -ne $ExpectedVersion }
                default { return $false }
            }
        }
        elseif ($DetectionType -eq "string") {
            switch ($Operator) {
                "equal" { return $ActualValue -eq $DetectionValue }
                "notEqual" { return $ActualValue -ne $DetectionValue }
                "contains" { return $ActualValue -like "*$DetectionValue*" }
                default { return $false }
            }
        }
        elseif ($DetectionType -eq "exists") {
            return $true
        }
    }
    catch {
        return $false
    }

    return $false
}

function Test-FileDetection {
    param(
        [string]$Path,
        [string]$FileOrFolderName,
        [string]$DetectionValue,
        [string]$Operator,
        [string]$DetectionType,
        [bool]$Check32BitOn64System
    )

    $FullPath = Join-Path -Path $Path -ChildPath $FileOrFolderName

    if (-not (Test-Path -Path $FullPath)) {
        return $false
    }

    if ($DetectionType -eq "version") {
        try {
            $FileVersion = (Get-Item -Path $FullPath).VersionInfo.FileVersion
            if ([string]::IsNullOrEmpty($FileVersion)) {
                return $false
            }

            $ActualVersion = [version]$FileVersion
            $ExpectedVersion = [version]$DetectionValue

            switch ($Operator) {
                "greaterThanOrEqual" { return $ActualVersion -ge $ExpectedVersion }
                "greaterThan" { return $ActualVersion -gt $ExpectedVersion }
                "equal" { return $ActualVersion -eq $ExpectedVersion }
                "lessThan" { return $ActualVersion -lt $ExpectedVersion }
                "lessThanOrEqual" { return $ActualVersion -le $ExpectedVersion }
                "notEqual" { return $ActualVersion -ne $ExpectedVersion }
                default { return $false }
            }
        }
        catch {
            return $false
        }
    }
    elseif ($DetectionType -eq "exists") {
        return $true
    }

    return $false
}

function Test-MsiProductCode {
    param(
        [string]$ProductCode,
        [string]$ProductVersion,
        [string]$ProductVersionOperator
    )

    $UninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    foreach ($UninstallPath in $UninstallPaths) {
        if (Test-Path -Path $UninstallPath) {
            $Apps = Get-ChildItem -Path $UninstallPath -ErrorAction SilentlyContinue
            foreach ($App in $Apps) {
                $AppProps = Get-ItemProperty -Path $App.PSPath -ErrorAction SilentlyContinue
                if ($AppProps.PSChildName -eq $ProductCode -or $AppProps.UninstallString -like "*$ProductCode*") {
                    if ([string]::IsNullOrEmpty($ProductVersion)) {
                        return $true
                    }

                    $InstalledVersion = [version]$AppProps.DisplayVersion
                    $ExpectedVersion = [version]$ProductVersion

                    switch ($ProductVersionOperator) {
                        "greaterThanOrEqual" { return $InstalledVersion -ge $ExpectedVersion }
                        "greaterThan" { return $InstalledVersion -gt $ExpectedVersion }
                        "equal" { return $InstalledVersion -eq $ExpectedVersion }
                        "lessThan" { return $InstalledVersion -lt $ExpectedVersion }
                        "lessThanOrEqual" { return $InstalledVersion -le $ExpectedVersion }
                        "notEqual" { return $InstalledVersion -ne $ExpectedVersion }
                        default { return $false }
                    }
                }
            }
        }
    }

    return $false
}

# Main script logic
try {
    # Parse JSON
    if (Test-Path -Path $DetectionJson -ErrorAction SilentlyContinue) {
        $Rules = Get-Content -Path $DetectionJson -Raw | ConvertFrom-Json
    }
    else {
        $Rules = $DetectionJson | ConvertFrom-Json
    }

    $AllRulesPassed = $true

    foreach ($Rule in $Rules) {
        $RulePassed = $false

        # Registry detection
        if ($Rule.keyPath -and $Rule.valueName) {
            $RulePassed = Test-RegistryDetection -KeyPath $Rule.keyPath `
                -ValueName $Rule.valueName `
                -DetectionValue $Rule.detectionValue `
                -Operator $Rule.operator `
                -DetectionType $Rule.detectionType `
                -Check32BitOn64System $Rule.check32BitOn64System
        }
        # File detection
        elseif ($Rule.path -and $Rule.fileOrFolderName) {
            $RulePassed = Test-FileDetection -Path $Rule.path `
                -FileOrFolderName $Rule.fileOrFolderName `
                -DetectionValue $Rule.detectionValue `
                -Operator $Rule.operator `
                -DetectionType $Rule.detectionType `
                -Check32BitOn64System $Rule.check32BitOn64System
        }
        # MSI product code detection
        elseif ($Rule.productCode) {
            $RulePassed = Test-MsiProductCode -ProductCode $Rule.productCode `
                -ProductVersion $Rule.productVersion `
                -ProductVersionOperator $Rule.productVersionOperator
        }

        if (-not $RulePassed) {
            $AllRulesPassed = $false
            break
        }
    }

    return $AllRulesPassed
}
catch {
    Write-Error "Detection failed: $($_.Exception.Message)"
    return $false
}
