# Comprehensive LiveKit SIP Service Connectivity Test
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  LIVEKIT SIP SERVICE CONNECTIVITY TEST  " -ForegroundColor Green  
Write-Host "==========================================" -ForegroundColor Green

$testResults = @{}

# Test 1: Port Connectivity
Write-Host "`n1. TESTING PORT CONNECTIVITY" -ForegroundColor Yellow
Write-Host "-----------------------------" -ForegroundColor Yellow

# Redis
$redis = Test-NetConnection -ComputerName "localhost" -Port 6379 -WarningAction SilentlyContinue
$testResults["Redis"] = $redis.TcpTestSucceeded
Write-Host "Redis (6379): " -NoNewline
if ($redis.TcpTestSucceeded) { Write-Host "CONNECTED" -ForegroundColor Green } else { Write-Host "FAILED" -ForegroundColor Red }

# LiveKit Server
$livekit = Test-NetConnection -ComputerName "localhost" -Port 7880 -WarningAction SilentlyContinue
$testResults["LiveKit"] = $livekit.TcpTestSucceeded
Write-Host "LiveKit (7880): " -NoNewline
if ($livekit.TcpTestSucceeded) { Write-Host "CONNECTED" -ForegroundColor Green } else { Write-Host "FAILED" -ForegroundColor Red }

# SIP Service
$sip = Test-NetConnection -ComputerName "localhost" -Port 5170 -WarningAction SilentlyContinue
$testResults["SIP"] = $sip.TcpTestSucceeded
Write-Host "SIP Service (5170): " -NoNewline
if ($sip.TcpTestSucceeded) { Write-Host "CONNECTED" -ForegroundColor Green } else { Write-Host "FAILED" -ForegroundColor Red }

# Health Check
$health = Test-NetConnection -ComputerName "localhost" -Port 8081 -WarningAction SilentlyContinue
$testResults["Health"] = $health.TcpTestSucceeded
Write-Host "Health Check (8081): " -NoNewline
if ($health.TcpTestSucceeded) { Write-Host "CONNECTED" -ForegroundColor Green } else { Write-Host "FAILED" -ForegroundColor Red }

# Test 2: API Response Tests
Write-Host "`n2. TESTING API RESPONSES" -ForegroundColor Yellow
Write-Host "------------------------" -ForegroundColor Yellow

# LiveKit API Health
try {
    $livekitResponse = Invoke-WebRequest -Uri "http://localhost:7880" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    Write-Host "LiveKit API Response: " -NoNewline
    Write-Host "HTTP $($livekitResponse.StatusCode)" -ForegroundColor Green
    $testResults["LiveKitAPI"] = $true
} catch {
    Write-Host "LiveKit API Response: " -NoNewline
    Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults["LiveKitAPI"] = $false
}

# Health Check Endpoint
try {
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:8081/health" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    Write-Host "Health Endpoint: " -NoNewline
    Write-Host "HTTP $($healthResponse.StatusCode)" -ForegroundColor Green
    $testResults["HealthAPI"] = $true
} catch {
    Write-Host "Health Endpoint: " -NoNewline
    Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testResults["HealthAPI"] = $false
}

# Test 3: Inter-Service Communication
Write-Host "`n3. TESTING INTER-SERVICE COMMUNICATION" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor Yellow

# Check active connections between services
$connections = netstat -an | Select-String "6379|7880|5170|8081" | Where-Object { $_ -match "ESTABLISHED" }
Write-Host "Active inter-service connections:"
if ($connections) {
    $connections | ForEach-Object { Write-Host "  $($_.Line)" -ForegroundColor Cyan }
    $testResults["InterServiceComm"] = $true
} else {
    Write-Host "  No established connections found" -ForegroundColor Yellow
    $testResults["InterServiceComm"] = $false
}

# Test 4: Redis Connectivity Test
Write-Host "`n4. TESTING REDIS FUNCTIONALITY" -ForegroundColor Yellow
Write-Host "------------------------------" -ForegroundColor Yellow

try {
    # Try to use local redis-cli first
    $redisTest = & "..\redis\redis-cli.exe" ping 2>$null
    if ($redisTest -eq "PONG") {
        Write-Host "Redis PING: " -NoNewline
        Write-Host "PONG (SUCCESS)" -ForegroundColor Green
        $testResults["RedisPing"] = $true
    } else {
        # Fallback to system redis-cli
        $redisTest = & redis-cli ping 2>$null
        if ($redisTest -eq "PONG") {
            Write-Host "Redis PING: " -NoNewline
            Write-Host "PONG (SUCCESS)" -ForegroundColor Green
            $testResults["RedisPing"] = $true
        } else {
            Write-Host "Redis PING: " -NoNewline
            Write-Host "No response" -ForegroundColor Red
            $testResults["RedisPing"] = $false
        }
    }
} catch {
    Write-Host "Redis PING: " -NoNewline
    Write-Host "redis-cli not available or failed" -ForegroundColor Yellow
    $testResults["RedisPing"] = $false
}

# Test 5: Service Process Check
Write-Host "`n5. CHECKING RUNNING PROCESSES" -ForegroundColor Yellow
Write-Host "-----------------------------" -ForegroundColor Yellow

# Check for SIP process
$sipProcess = Get-Process -Name "sip" -ErrorAction SilentlyContinue
Write-Host "SIP Process: " -NoNewline
if ($sipProcess) { 
    Write-Host "RUNNING (PID: $($sipProcess.Id))" -ForegroundColor Green
    $testResults["SIPProcess"] = $true
} else { 
    Write-Host "NOT RUNNING" -ForegroundColor Red
    $testResults["SIPProcess"] = $false
}

# Check for LiveKit process
$livekitProcess = Get-Process -Name "livekit*" -ErrorAction SilentlyContinue
Write-Host "LiveKit Process: " -NoNewline
if ($livekitProcess) { 
    Write-Host "RUNNING (PID: $($livekitProcess.Id))" -ForegroundColor Green
    $testResults["LiveKitProcess"] = $true
} else { 
    Write-Host "NOT RUNNING" -ForegroundColor Red
    $testResults["LiveKitProcess"] = $false
}

# Test Results Summary
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "             TEST RESULTS SUMMARY        " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$totalTests = $testResults.Count
$passedTests = ($testResults.Values | Where-Object { $_ -eq $true }).Count
$failedTests = $totalTests - $passedTests

Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round(($passedTests/$totalTests)*100, 1))%" -ForegroundColor Yellow

Write-Host "`nDetailed Results:" -ForegroundColor White
foreach ($test in $testResults.GetEnumerator()) {
    $status = if ($test.Value) { "PASS" } else { "FAIL" }
    $color = if ($test.Value) { "Green" } else { "Red" }
    Write-Host "  $($test.Key): " -NoNewline
    Write-Host $status -ForegroundColor $color
}

if ($passedTests -eq $totalTests) {
    Write-Host "`n🎉 ALL SERVICES ARE CONNECTED AND WORKING!" -ForegroundColor Green
} elseif ($passedTests -gt ($totalTests / 2)) {
    Write-Host "`n⚠️  MOST SERVICES WORKING - Some issues detected" -ForegroundColor Yellow
} else {
    Write-Host "`n❌ MAJOR CONNECTIVITY ISSUES DETECTED" -ForegroundColor Red
}

Write-Host "`n==========================================" -ForegroundColor Cyan