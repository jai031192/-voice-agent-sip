#!/usr/bin/env powershell

Write-Host "=== LiveKit SIP Test Environment ===" -ForegroundColor Green
Write-Host ""

# Check services status
Write-Host "Checking Services Status:" -ForegroundColor Yellow

# Check Redis
try {
    $redisResult = & redis\redis-cli.exe ping 2>$null
    if ($redisResult -eq "PONG") {
        Write-Host "✅ Redis: Running" -ForegroundColor Green
    } else {
        Write-Host "❌ Redis: Not responding" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Redis: Not running" -ForegroundColor Red
}

# Check LiveKit Server
try {
    $liveKitResult = Invoke-WebRequest -Uri "http://localhost:7880" -TimeoutSec 5 -ErrorAction Stop
    if ($liveKitResult.StatusCode -eq 200) {
        Write-Host "✅ LiveKit Server: Running" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ LiveKit Server: Not responding" -ForegroundColor Red
}

# Check SIP Service
$sipProcess = Get-Process -Name "sip" -ErrorAction SilentlyContinue
if ($sipProcess) {
    Write-Host "✅ SIP Service: Running (PID: $($sipProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "❌ SIP Service: Not running" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Service URLs ===" -ForegroundColor Yellow
Write-Host "LiveKit Server: http://localhost:7880"
Write-Host "SIP Service: localhost:5060"
Write-Host "Redis: localhost:6379"
Write-Host ""
Write-Host "=== API Credentials ===" -ForegroundColor Yellow
Write-Host "API Key: 108378f337bbab3ce4e944554bed555a"
Write-Host "API Secret: 2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d"
Write-Host ""

# Room management
Write-Host "=== Room Management ===" -ForegroundColor Yellow
Write-Host "Test Room: sip-test-room"

    $env:LIVEKIT_API_KEY="108378f337bbab3ce4e944554bed555a"
    $env:LIVEKIT_API_SECRET="2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d"

# Quick actions menu
Write-Host "=== Quick Actions ===" -ForegroundColor Cyan
Write-Host "1. Start all services"
Write-Host "2. Stop all services"
Write-Host "3. View SIP logs"
Write-Host "4. Test room creation"
Write-Host "5. Exit"

$choice = Read-Host "Enter choice (1-5)"

switch ($choice) {
    "1" {
        Write-Host "Starting services..." -ForegroundColor Yellow
        Start-Process -FilePath "redis\redis-server.exe" -WindowStyle Hidden
        Start-Sleep 2
        Start-Process -FilePath "livekit\livekit-server.exe" -ArgumentList "--config", "livekit-config.yaml"
        Start-Sleep 3
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD'; .\sip.exe --config config.yaml"
    }
    "2" {
        Write-Host "Stopping services..." -ForegroundColor Yellow
        Stop-Process -Name "sip" -Force -ErrorAction SilentlyContinue
        Stop-Process -Name "livekit-server" -Force -ErrorAction SilentlyContinue
        Stop-Process -Name "redis-server" -Force -ErrorAction SilentlyContinue
    }
    "3" {
        Write-Host "SIP service should be running in a separate window for logs"
    }
    "4" {
        $env:LIVEKIT_URL="http://localhost:7880"
    $env:LIVEKIT_API_KEY="108378f337bbab3ce4e944554bed555a"
    $env:LIVEKIT_API_SECRET="2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d"
        livekit-cli create-room --name "test-room-$(Get-Date -Format 'HHmmss')"
    }
    "5" {
        Write-Host "Goodbye!" -ForegroundColor Green
        exit
    }
}