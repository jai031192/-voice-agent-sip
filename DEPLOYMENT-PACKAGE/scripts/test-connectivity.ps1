# LiveKit SIP Service Test Script for Windows
# Tests connectivity between Redis, SIP Service, and LiveKit Server

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
        Write-Host "   Start Redis first: redis-server" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Redis connection test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Check if LiveKit Server is running
Write-Host "`n🎥 Testing LiveKit Server Connection..." -ForegroundColor Yellow
try {
    $livekitTest = Test-NetConnection -ComputerName "localhost" -Port 7880 -WarningAction SilentlyContinue
    if ($livekitTest.TcpTestSucceeded) {
        Write-Host "✅ LiveKit Server port 7880 is accessible" -ForegroundColor Green
        
        # Try to get health status
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:7880" -TimeoutSec 5 -UseBasicParsing
            Write-Host "✅ LiveKit Server is responding (Status: $($response.StatusCode))" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  LiveKit port is open but server might not be fully ready" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ LiveKit Server port 7880 is not accessible" -ForegroundColor Red
        Write-Host "   Start LiveKit Server first" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ LiveKit Server connection test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Check if SIP Service port is available
Write-Host "`n📞 Testing SIP Service Port..." -ForegroundColor Yellow
try {
    $sipTest = Test-NetConnection -ComputerName "localhost" -Port 5170 -WarningAction SilentlyContinue
    if ($sipTest.TcpTestSucceeded) {
        Write-Host "✅ SIP Service port 5170 is accessible" -ForegroundColor Green
    } else {
        Write-Host "❌ SIP Service port 5170 is not accessible" -ForegroundColor Red
        Write-Host "   SIP service might not be running" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ SIP Service connection test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Check if Health Check port is available
Write-Host "`n🏥 Testing Health Check Port..." -ForegroundColor Yellow
try {
    $healthTest = Test-NetConnection -ComputerName "localhost" -Port 8080 -WarningAction SilentlyContinue
    if ($healthTest.TcpTestSucceeded) {
        Write-Host "✅ Health Check port 8080 is accessible" -ForegroundColor Green
        
        # Try to get health status
        try {
            $healthResponse = Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 5 -UseBasicParsing
            Write-Host "✅ Health endpoint is responding (Status: $($healthResponse.StatusCode))" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Health port is open but endpoint might not be ready" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Health Check port 8080 is not accessible" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Health Check connection test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Check network configuration
Write-Host "`n🌐 Network Configuration Check..." -ForegroundColor Yellow
try {
    $localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.*"} | Select-Object -First 1).IPAddress
    Write-Host "✅ Local IP Address: $localIP" -ForegroundColor Green
    
    # Check if this matches your expected IP
    if ($localIP -eq "40.81.229.194") {
        Write-Host "✅ IP matches your configured external IP" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Local IP ($localIP) differs from configured external IP (40.81.229.194)" -ForegroundColor Yellow
        Write-Host "   This is normal if running locally" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Network configuration check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n📋 Test Summary:" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
Write-Host "To start all services manually:" -ForegroundColor White
Write-Host "1. Start Redis: redis-server" -ForegroundColor Gray
Write-Host "2. Start LiveKit: livekit-server --config livekit-config.yaml" -ForegroundColor Gray
Write-Host "3. Start SIP Service: ./sip-app --config config.yaml" -ForegroundColor Gray
Write-Host ""
Write-Host "For Docker deployment, install Docker Desktop first:" -ForegroundColor White
Write-Host "https://docs.docker.com/desktop/install/windows-install/" -ForegroundColor Gray