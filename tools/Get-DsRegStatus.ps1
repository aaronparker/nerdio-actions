function ConvertTo-UniversalTime {
    param ([System.String]$String)
    try {
        $dt = [DateTime]::ParseExact($String, "yyyy-MM-dd HH:mm:ss.fff UTC", $null)
        return $dt.ToUniversalTime().ToString("o")
    }
    catch {
        $dt = [DateTime]::ParseExact($String, "MM-dd-yyyy H:mm:ss'Z'", $null, [System.Globalization.DateTimeStyles]::AssumeUniversal)
        return $dt.ToUniversalTime().ToString("o")
    }
}

function Get-DsRegStatus {
    $Output = & "$Env:SystemRoot\System32\dsregcmd.exe" /status | Out-String
    $DsRegTable = $Output -split "`n" | ForEach-Object {
        if ($_ -match "^(.*?):\s*(.*)$") {
            [PSCustomObject]@{
                Key   = $matches[1].Trim()
                Value = $matches[2].Trim()
            }
        }
    }
    $DsRegObject = [PSCustomObject]@{}
    foreach ($item in $DsRegTable) {
        switch ($item.Value) {
            "YES" { $item.Value = $true }
            "NO" { $item.Value = $false }
        }
        if ($item.Key -notlike "For more information*") {
            switch -regex ($item.Key) {
                "AzureAdPrtUpdateTime|AzureAdPrtExpiryTime|Client Time|Server Time" {
                    $DsRegObject | Add-Member -MemberType "NoteProperty" -Name ($item.Key -replace "\s+", "") -Value (ConvertTo-UniversalTime $item.Value)
                }
                "Executing Account Name|KerbTopLevelNames" {
                    $DsRegObject | Add-Member -MemberType "NoteProperty" -Name ($item.Key -replace "\s+", "") -Value (($item.Value -split ",").Trim())
                }
                "WamDefaultGUID" {
                    $DsRegObject | Add-Member -MemberType "NoteProperty" -Name ($item.Key -replace "\s+", "") -Value ($item.Value -replace "\s+\(AzureAd\)", "")
                }
                "DeviceCertificateValidity" {
                    $Times = $($item.Value -split "--").Trim("[  ]")
                    $CertificateValidity = [PSCustomObject]@{
                        ValidFrom = ConvertTo-UniversalTime $Times[0]
                        ValidTo   = ConvertTo-UniversalTime $Times[1]
                    }
                    $DsRegObject | Add-Member -MemberType "NoteProperty" -Name $item.Key -Value $CertificateValidity
                }
                default {
                    $DsRegObject | Add-Member -MemberType "NoteProperty" -Name ($item.Key -replace "\s+|-", "") -Value $item.Value
                }
            }
        }
    }
    return $DsRegObject
}

Get-DsRegStatus
