<#
.SYNOPSIS
    Standalone diagnostic script for iPhone USB Tethering on Windows.
.DESCRIPTION
    Quickly verifies PnP hardware detection (VID 05AC), NDIS adapter state,
    gateway ping (172.20.10.1), DNS resolution, and WAN HTTP reachability.
#>

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   iPhone USB Tethering Assistant - Live Diagnostic Probe" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. PnP Check for Apple USB Vendor ID (05AC)
Write-Host "[1/4] Checking PnP Devices for Apple USB Hardware (VID_05AC)..." -NoNewline
$appleDevices = Get-PnpDevice -PresentOnly 2>$null | Where-Object { $_.InstanceId -like "*VID_05AC*" }
if ($appleDevices) {
    Write-Host " [PASS]" -ForegroundColor Green
    foreach ($dev in $appleDevices) {
        Write-Host "      Found: $($dev.FriendlyName) ($($dev.Class))" -ForegroundColor Gray
    }
} else {
    Write-Host " [FAIL]" -ForegroundColor Red
    Write-Host "      No Apple USB device found. Check physical USB cable connection." -ForegroundColor Yellow
}

# 2. Check for Tethering Gateway (172.20.10.1)
Write-Host "`n[2/4] Scanning Network Interfaces for 172.20.10.1 Subnet..." -NoNewline
$tetherNic = Get-NetIPConfiguration 2>$null | Where-Object {
    $_.IPv4DefaultGateway.NextHop -eq "172.20.10.1"
}

if ($tetherNic) {
    Write-Host " [PASS]" -ForegroundColor Green
    Write-Host "      Adapter : $($tetherNic.InterfaceAlias)" -ForegroundColor Gray
    Write-Host "      IPv4    : $($tetherNic.IPv4Address.IPAddress)" -ForegroundColor Gray
    Write-Host "      Gateway : $($tetherNic.IPv4DefaultGateway.NextHop)" -ForegroundColor Gray
} else {
    Write-Host " [FAIL]" -ForegroundColor Red
    Write-Host "      No interface with Gateway 172.20.10.1 found." -ForegroundColor Yellow
    Write-Host "      Action: Ensure 'Personal Hotspot' is toggled ON in iPhone Settings." -ForegroundColor Yellow
}

# 3. Gateway Ping
Write-Host "`n[3/4] Testing Gateway ICMP Echo (172.20.10.1)..." -NoNewline
$ping = Test-Connection -ComputerName "172.20.10.1" -Count 2 -Quiet 2>$null
if ($ping) {
    Write-Host " [PASS]" -ForegroundColor Green
    Write-Host "      iPhone tethering daemon responded successfully." -ForegroundColor Gray
} else {
    Write-Host " [FAIL]" -ForegroundColor Red
    Write-Host "      iPhone gateway did not reply. The daemon might be suspended." -ForegroundColor Yellow
}

# 4. WAN Reachability Probe
Write-Host "`n[4/4] Testing WAN Connectivity (Cloudflare HTTP 204 Probe)..." -NoNewline
try {
    $res = Invoke-WebRequest -Uri "http://cp.cloudflare.com/generate_204" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
    if ($res.StatusCode -eq 204) {
        Write-Host " [PASS]" -ForegroundColor Green
        Write-Host "      Full Internet connectivity confirmed." -ForegroundColor Gray
    } else {
        Write-Host " [WARN]" -ForegroundColor Yellow
        Write-Host "      Unexpected status code: $($res.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host " [FAIL]" -ForegroundColor Red
    Write-Host "      Failed to reach external WAN. Check iPhone cellular data switch." -ForegroundColor Yellow
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "Diagnostic Complete." -ForegroundColor Cyan

