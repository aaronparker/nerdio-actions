function ConvertTo-UniversalTime {
    param (
        [System.String]$DateString
    )
    try {
        $dt = [DateTime]::ParseExact($DateString, "yyyy-MM-dd HH:mm:ss.fff UTC", $null)
        return $dt.ToUniversalTime().ToString("o")
    } catch {
        return $null
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
        if ($item.Key -notlike "For more information*") {
            switch -regex ($item.Key) {
                "AzureAdPrtUpdateTime|AzureAdPrtExpiryTime" {
                    $DsRegObject | Add-Member -MemberType "NoteProperty" -Name $item.Key -Value (ConvertTo-UniversalTime $item.Value.Trim())
                }
                "ClientTime" {
                    $DsRegObject | Add-Member -MemberType "NoteProperty" -Name $item.Key -Value (ConvertTo-UniversalTime $item.Value.Trim())
                }
                "ExecutingAccountName*" {
                    $DsRegObject | Add-Member -MemberType "NoteProperty" -Name $item.Key -Value ($item.Value -split ",")
                }
                default {
                    $DsRegObject | Add-Member -MemberType "NoteProperty" -Name ($item.Key -replace "\s+", "") -Value $item.Value
                }
            }
        }
    }
    return $DsRegObject
}

Get-DsRegStatus
