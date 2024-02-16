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
            # Construct additional information
            $additionalInfo = "`tNumber of Reports: $($abuseReport.data.totalReports)`n`tConfidence of Abuse: $($abuseReport.data.abuseConfidenceScore)`n`tCountry: $($abuseReport.data.countryCode)`n`tDomain: $($abuseReport.data.domain)`n`tISP: $($abuseReport.data.isp)"
    
            # Construct output string
            $output = "IP $ipAddress has reports!`n$additionalInfo"
    
            $ipsWithDetections += $output  # Store complete output for grouping
        } else {
            $ipsWithoutDetections += $ipAddress
        }
        Mark-Checked -ipAddress $ipAddress
    }

# Notify on IPs with detections
if ($ipsWithDetections.Count -gt 0) {
    Write-Host "`nIP's with detections:"
    $ipsWithDetections | ForEach-Object { Write-Host "$_" }
}

# Add two lines of space between sections
Write-Host "`n`n"

# Notify on IPs without detections
if ($ipsWithoutDetections.Count -gt 0) {
    Write-Host "IP's without detections:"
    $ipsWithoutDetections | ForEach-Object { Write-Host "$_" }
}

    # Sleep for n seconds before the next iteration
    Start-Sleep -Seconds 300  # Adjust as needed
}
