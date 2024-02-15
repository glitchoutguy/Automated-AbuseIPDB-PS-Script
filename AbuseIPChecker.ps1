# Function to query AbuseIPDB API
function Get-AbuseIPReport {
    param(
        [string]$ipAddress
    )

    $apiKey = "YOUR API KEY HERE"
    $url = "https://api.abuseipdb.com/api/v2/check?ipAddress=$ipAddress"

    $headers = @{
        "Key" = $apiKey
    }

    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

    return $response
}

# Function to check if an IP address has been checked within the last 24 hours
function Is-RecentlyChecked {
    param(
        [string]$ipAddress
    )

    $lastCheckedFile = "lastChecked.txt"

    if (Test-Path $lastCheckedFile) {
        $lastChecked = Get-Content $lastCheckedFile
        $lastCheckedDate = [datetime]::ParseExact($lastChecked, "yyyy-MM-dd HH:mm:ss", $null)
        $elapsedHours = (Get-Date) - $lastCheckedDate
        if ($elapsedHours.TotalHours -lt 24) {
            return $true
        }
    }

    return $false
}

# Function to mark an IP address as checked
function Mark-Checked {
    param(
        [string]$ipAddress
    )

    $lastCheckedFile = "lastChecked.txt"
    $currentTime = Get-Date
    $currentTimeString = $currentTime.ToString("yyyy-MM-dd HH:mm:ss")
    $currentTimeString | Set-Content $lastCheckedFile
}

# Infinite loop
while ($true) {
    # Get foreign addresses from netstat -ano command
    $netstatOutput = netstat -ano
    $foreignAddresses = $netstatOutput -split "`n" | Select-String -Pattern '\d+\.\d+\.\d+\.\d+:(\d+)\s+(\d+\.\d+\.\d+\.\d+):(\d+)' -AllMatches | ForEach-Object { $_.Matches.Groups[2].Value }

    # Filter out duplicates, local/loopback addresses, and 0.0.0.0
    $foreignAddresses = $foreignAddresses | Where-Object { $_ -and $_ -ne "0.0.0.0" -and $_ -notmatch '^127\.' -and $_ -notmatch '^192\.168\.' -and $_ -notmatch '^10\.' }

    # Remove recently checked IP addresses
    $foreignAddresses = $foreignAddresses | Where-Object { -not (Is-RecentlyChecked $_) }

    # Initialize arrays to store IPs with detections and without detections
    $ipsWithDetections = @()
    $ipsWithoutDetections = @()

    # Check each foreign IP address against AbuseIPDB
    foreach ($ipAddress in $foreignAddresses) {
        $abuseReport = Get-AbuseIPReport -ipAddress $ipAddress
        if ($abuseReport.data.totalReports -gt 0) {
            Write-Host "IP $ipAddress has reports!"
            $ipsWithDetections += $ipAddress
        } else {
            $ipsWithoutDetections += $ipAddress
        }
        Mark-Checked -ipAddress $ipAddress
    }

    # Notify on each checked IP
    $ipsWithDetections | ForEach-Object { Write-Host "IP $_ has reports!" }
    $ipsWithoutDetections | ForEach-Object { Write-Host "IP $_ has no reports." }

    # Sleep for n seconds before the next iteration
    Start-Sleep -Seconds 300  # Adjust as needed
}
# SIG # Begin signature block
# MIIFnQYJKoZIhvcNAQcCoIIFjjCCBYoCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFVbfFm3Cv9bKFl/JIhDFar15
# xzegggMzMIIDLzCCAhegAwIBAgIQSUXuwW3A/LpAYYr7rP+ZszANBgkqhkiG9w0B
# AQsFADAfMR0wGwYDVQQDDBRQUyBDb2RlIFNpZ25pbmcgQ2VydDAeFw0yNDAyMTUy
# MTUwNDlaFw0yNTAyMTUyMjEwNDlaMB8xHTAbBgNVBAMMFFBTIENvZGUgU2lnbmlu
# ZyBDZXJ0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAp0PDyo3aXZKp
# MbxHyKSJP4H234GpSR1hOLIl32ZlunZw7IrbWTyiNIfZobttUWUuWDrrgsJqw1zZ
# vYOPQusD4e35TAayrypeOk4kBLFunWkMb3e9Xg9zz+OI5bPa9ySkvilX6Hm/3Crh
# vm4RLyCR1rV5OflQscYmGzfYL4tEHakl1576MdgpI62eZeG0VtUYaFTDdxSa2NT5
# 9g53dWceAmsAHjuIO+L9DBA8VXo7wnYa5bK0zHzSIdihKx9MxaCdikI6O4V7MwNJ
# CdYdGXLLscLs958SblMcveMNRXfpGEIXShf4jPe1FEC2LcUxhtslu6PBtnxR4v/s
# 4Yiu3iJAiQIDAQABo2cwZTAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwHwYDVR0RBBgwFoIUUFMgQ29kZSBTaWduaW5nIENlcnQwHQYDVR0OBBYE
# FECQl7MFZv0wzxSdPDj3MHaejjpkMA0GCSqGSIb3DQEBCwUAA4IBAQAJmG7UOx8h
# SwbH4qIfNMoL4VQgPPMghJWC03LrGHhM2ex0kyV4z5vDCWpQZIRduRbeIWc3EIms
# iA9yPQn2us1efnwYvLMmPzc0R/AGz3zS9qlKZa1gPLaFfd6cGd0GzeWaOyPfdeh5
# 4uGDYEdc3S+XgsxSXafyyuyBuo8vyDu179+UwxHzXNTDHannUBylZikok5p9YQ2X
# PXQrYjlACbRH8jr2LF9cSVyrzYL5lUK1/aLDk6DSP9pyjGpIFxPyQii1kFTj2PLC
# FDfRlJX3qO2xwPwoUerA+EMee231iVjD7vm5ZIJdFwpNd9rtkjs3rlrLW1tj4sOk
# PxEfKtE9k4NRMYIB1DCCAdACAQEwMzAfMR0wGwYDVQQDDBRQUyBDb2RlIFNpZ25p
# bmcgQ2VydAIQSUXuwW3A/LpAYYr7rP+ZszAJBgUrDgMCGgUAoHgwGAYKKwYBBAGC
# NwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUPomh+wOY
# RDAV4Qg87vKe9urvDuUwDQYJKoZIhvcNAQEBBQAEggEAk0j62p1OKh0YQZ2fSPRh
# lXcXCnVzqtkJNRevrYLwy6DZD/Tl5z7o0CY+k9KvhNzs34Xr+JXwZSjQmE4BZj3k
# jzNlNfRL1OrUNJ90SdBA+jYilKBHKie70+BpvDbIqTgjxN/kXQk/yFKvfxvgVD+/
# mpM6WAlpO9KxHtfuCV2macSPk+2qP3w1s968U0EGU0tI4QbMSV3vYmE4CTESqRcC
# truglEKGwsU+IJLyGVC7Be9gZvQ6LrRWCPZqZkQqUhuTfI9bWMA12AX+fOs0FSvh
# VAcqJ5ARJcRHCm0qh/92Bvcn0nRxciDPbgJCK0kn243dytzj6FCKO6HP9Az0oNva
# FA==
# SIG # End signature block
