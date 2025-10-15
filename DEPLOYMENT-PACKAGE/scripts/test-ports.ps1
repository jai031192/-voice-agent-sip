# LiveKit SIP Service Connection Test
Write-Host "LiveKit SIP Service Connection Test" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

# Test Redis
Write-Host "Testing Redis Connection (port 6379)..." -ForegroundColor Yellow
$redisTest = Test-NetConnection -ComputerName "localhost" -Port 6379 -WarningAction SilentlyContinue
if ($redisTest.TcpTestSucceeded) {
    Write-Host "SUCCESS: Redis port 6379 is accessible" -ForegroundColor Green
} else {
    Write-Host "FAILED: Redis port 6379 is not accessible" -ForegroundColor Red
}

# Test LiveKit Server
Write-Host "Testing LiveKit Server Connection (port 7880)..." -ForegroundColor Yellow
$livekitTest = Test-NetConnection -ComputerName "localhost" -Port 7880 -WarningAction SilentlyContinue
if ($livekitTest.TcpTestSucceeded) {
    Write-Host "SUCCESS: LiveKit Server port 7880 is accessible" -ForegroundColor Green
} else {
    Write-Host "FAILED: LiveKit Server port 7880 is not accessible" -ForegroundColor Red
}

# Test SIP Service
Write-Host "Testing SIP Service Port (port 5170)..." -ForegroundColor Yellow
$sipTest = Test-NetConnection -ComputerName "localhost" -Port 5170 -WarningAction SilentlyContinue
if ($sipTest.TcpTestSucceeded) {
    Write-Host "SUCCESS: SIP Service port 5170 is accessible" -ForegroundColor Green
} else {
    Write-Host "FAILED: SIP Service port 5170 is not accessible" -ForegroundColor Red
}

Write-Host "Test Complete!" -ForegroundColor Cyan