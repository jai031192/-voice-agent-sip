# Production Environment Test Script for LiveKit SIP Service
# Tests connectivity to production server: 40.81.229.194

param(
    [string]$ServerIP = "40.81.229.194",
    [switch]$Verbose
)

Write-Host "=== LiveKit SIP Production Test Suite ===" -ForegroundColor Green
Write-Host "Testing server: $ServerIP" -ForegroundColor Yellow
Write-Host ""

$testResults = @()
$totalTests = 0
$passedTests = 0

function Test-Service {
    param(
        [string]$Name,
        [string]$TestCommand,
        [string]$Description
    )
    
    $global:totalTests++
    Write-Host "[$global:totalTests] Testing $Name..." -NoNewline
    
    try {
        $result = Invoke-Expression $TestCommand
        if ($result) {
            Write-Host " PASS" -ForegroundColor Green
            if ($Verbose) { Write-Host "    $Description" -ForegroundColor Gray }
            $global:passedTests++
            $global:testResults += [PSCustomObject]@{
                Test = $Name
                Status = "PASS"
                Details = $Description
            }
            return $true
        }
    }
    catch {
        Write-Host " FAIL" -ForegroundColor Red
        if ($Verbose) { Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red }
        $global:testResults += [PSCustomObject]@{
            Test = $Name
            Status = "FAIL" 
            Details = $_.Exception.Message
        }
        return $false
    }
    
    Write-Host " FAIL" -ForegroundColor Red
    $global:testResults += [PSCustomObject]@{
        Test = $Name
        Status = "FAIL"
        Details = "Test returned false or null"
    }
    return $false
}

# Test 1: Server Connectivity
Test-Service "Server Ping" "Test-NetConnection -ComputerName $ServerIP -InformationLevel Quiet" "Basic network connectivity to production server"

# Test 2: Redis (Production)
Test-Service "Redis Connection" "Test-NetConnection -ComputerName $ServerIP -Port 6379 -InformationLevel Quiet" "Redis database connectivity"

# Test 3: LiveKit WebSocket (Production)  
Test-Service "LiveKit Port" "Test-NetConnection -ComputerName $ServerIP -Port 7880 -InformationLevel Quiet" "LiveKit WebRTC server connectivity"

# Test 4: SIP Service Port (MONKHUB)
Test-Service "SIP Service" "Test-NetConnection -ComputerName $ServerIP -Port 5170 -InformationLevel Quiet" "SIP service on MONKHUB port"

# Test 5: Health Endpoint
Test-Service "Health Check" "`$null -ne (Test-NetConnection -ComputerName $ServerIP -Port 8080 -InformationLevel Quiet)" "Application health endpoint"

# Test 6: Metrics Endpoint  
Test-Service "Metrics" "`$null -ne (Test-NetConnection -ComputerName $ServerIP -Port 9090 -InformationLevel Quiet)" "Prometheus metrics endpoint"

# Test 7: DNS Resolution
Test-Service "DNS Resolution" "`$null -ne (Resolve-DnsName -Name 'google.com' -ErrorAction SilentlyContinue)" "External DNS resolution from server"

Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Yellow
Write-Host "Total Tests: $totalTests"
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $($totalTests - $passedTests)" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor Cyan

if ($Verbose) {
    Write-Host ""
    Write-Host "=== Detailed Results ===" -ForegroundColor Yellow
    $testResults | Format-Table -AutoSize
}

Write-Host ""
if ($passedTests -eq $totalTests) {
    Write-Host "ALL TESTS PASSED! Production environment is ready." -ForegroundColor Green
    exit 0
} else {
    Write-Host "Some tests failed. Please check the production environment configuration." -ForegroundColor Red
    exit 1
}