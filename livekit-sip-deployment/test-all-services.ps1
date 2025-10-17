# Complete Service Status Check
Write-Host "=== LIVEKIT SIP SERVICE STATUS CHECK ===" -ForegroundColor Green

# Check Redis
$redis = Test-NetConnection -ComputerName "localhost" -Port 6379 -WarningAction SilentlyContinue
Write-Host "Redis (6379): " -NoNewline
if ($redis.TcpTestSucceeded) { Write-Host "RUNNING" -ForegroundColor Green } else { Write-Host "STOPPED" -ForegroundColor Red }

# Check LiveKit Server
$livekit = Test-NetConnection -ComputerName "localhost" -Port 7880 -WarningAction SilentlyContinue
Write-Host "LiveKit (7880): " -NoNewline  
if ($livekit.TcpTestSucceeded) { Write-Host "RUNNING" -ForegroundColor Green } else { Write-Host "STOPPED" -ForegroundColor Red }

# Check SIP Service
$sip = Test-NetConnection -ComputerName "localhost" -Port 5170 -WarningAction SilentlyContinue
Write-Host "SIP Service (5170): " -NoNewline
if ($sip.TcpTestSucceeded) { Write-Host "RUNNING" -ForegroundColor Green } else { Write-Host "STOPPED" -ForegroundColor Red }

# Test Redis connection via ping
Write-Host "`nTesting Redis ping..." -ForegroundColor Yellow
try {
    $redisResponse = & redis-cli ping 2>$null
    if ($redisResponse -eq "PONG") {
        Write-Host "SUCCESS: Redis responds to PING" -ForegroundColor Green
    } else {
        Write-Host "FAILED: Redis not responding" -ForegroundColor Red
    }
} catch {
    Write-Host "FAILED: redis-cli not available or Redis not responding" -ForegroundColor Red
}

# Check all ports being used
Write-Host "`nActive network connections:" -ForegroundColor Yellow
netstat -an | Select-String "6379|7880|5170" | ForEach-Object { Write-Host $_.Line -ForegroundColor Cyan }

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "All three services need to be running for proper SIP functionality:" -ForegroundColor White
Write-Host "- Redis: State management and coordination" -ForegroundColor Gray
Write-Host "- LiveKit Server: WebRTC room management" -ForegroundColor Gray  
Write-Host "- SIP Service: SIP protocol handling and audio conversion" -ForegroundColor Gray