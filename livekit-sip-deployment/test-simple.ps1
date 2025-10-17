# LiveKit SIP Service Test Script for Windows
Write-Host "🚀 LiveKit SIP Service Connection Test" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Test 1: Check if Redis is running
Write-Host "`n📊 Testing Redis Connection..." -ForegroundColor Yellow
try {
    $redisTest = Test-NetConnection -ComputerName "localhost" -Port 6379 -WarningAction SilentlyContinue
    if ($redisTest.TcpTestSucceeded) {
        Write-Host "✅ Redis port 6379 is accessible" -ForegroundColor Green
    } else {
        Write-Host "❌ Redis port 6379 is not accessible" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Redis connection failed" -ForegroundColor Red
}

# Test 2: Check if LiveKit Server is running
Write-Host "`n🎥 Testing LiveKit Server Connection..." -ForegroundColor Yellow
try {
    $livekitTest = Test-NetConnection -ComputerName "localhost" -Port 7880 -WarningAction SilentlyContinue
    if ($livekitTest.TcpTestSucceeded) {
        Write-Host "✅ LiveKit Server port 7880 is accessible" -ForegroundColor Green
    } else {
        Write-Host "❌ LiveKit Server port 7880 is not accessible" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ LiveKit Server connection failed" -ForegroundColor Red
}

# Test 3: Check if SIP Service port is available
Write-Host "`n📞 Testing SIP Service Port..." -ForegroundColor Yellow
try {
    $sipTest = Test-NetConnection -ComputerName "localhost" -Port 5170 -WarningAction SilentlyContinue
    if ($sipTest.TcpTestSucceeded) {
        Write-Host "✅ SIP Service port 5170 is accessible" -ForegroundColor Green
    } else {
        Write-Host "❌ SIP Service port 5170 is not accessible" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ SIP Service connection failed" -ForegroundColor Red
}

# Test 4: Check network configuration
Write-Host "`n🌐 Network Configuration Check..." -ForegroundColor Yellow
try {
    $localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.*"} | Select-Object -First 1).IPAddress
    Write-Host "✅ Local IP Address: $localIP" -ForegroundColor Green
} catch {
    Write-Host "❌ Network configuration check failed" -ForegroundColor Red
}

Write-Host "`n📋 Test Complete!" -ForegroundColor Cyan