#!/usr/bin/env powershell
# SIP Service Startup and Configuration Script

Write-Host "=== LiveKit SIP Setup Completion ===" -ForegroundColor Cyan
Write-Host ""

# Set environment variables
$env:LIVEKIT_URL = "http://localhost:7880"
$env:LIVEKIT_API_KEY = "API5DcPxqyBDHLr"
$env:LIVEKIT_API_SECRET = "b9dgi6VEHsXf1zLKFWffHONECta5Xvfs5ejgdZhUoxPE"

Write-Host "Environment configured:" -ForegroundColor Yellow
Write-Host "- LiveKit URL: $env:LIVEKIT_URL"
Write-Host "- API Key: $env:LIVEKIT_API_KEY"
Write-Host ""

# Function to check if process is running
function Test-ProcessRunning {
    param([string]$ProcessName)
    return (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue) -ne $null
}

# Check LiveKit Server
Write-Host "Checking LiveKit Server..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:7880" -TimeoutSec 5 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ LiveKit Server: Running" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ LiveKit Server: Not responding" -ForegroundColor Red
    Write-Host "Please start: livekit\livekit-server.exe --config livekit-config.yaml"
    exit
}

# Check Redis
Write-Host "Checking Redis..." -ForegroundColor Yellow
try {
    $redisResult = & redis\redis-cli.exe ping 2>$null
    if ($redisResult -eq "PONG") {
        Write-Host "✅ Redis: Running" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Redis: Not running" -ForegroundColor Red
    Write-Host "Please start: redis\redis-server.exe"
    exit
}

# Start SIP Service with retry
Write-Host "Starting SIP Service..." -ForegroundColor Yellow
$sipStarted = $false
for ($i = 1; $i -le 3; $i++) {
    try {
        Write-Host "Attempt $i of 3..." -ForegroundColor Gray
        $sipProcess = Start-Process -FilePath ".\sip.exe" -ArgumentList "--config", "config.yaml" -PassThru -WindowStyle Hidden
        Start-Sleep 5
        
        if (!$sipProcess.HasExited) {
            Write-Host "✅ SIP Service: Started (PID: $($sipProcess.Id))" -ForegroundColor Green
            $sipStarted = $true
            break
        }
    } catch {
        Write-Host "Attempt $i failed, retrying..." -ForegroundColor Red
        Start-Sleep 2
    }
}

if (!$sipStarted) {
    Write-Host "❌ SIP Service: Failed to start after 3 attempts" -ForegroundColor Red
    Write-Host "Manual start required: .\sip.exe --config config.yaml"
    exit
}

# Wait for SIP service to fully initialize
Write-Host "Waiting for SIP service initialization..." -ForegroundColor Yellow
Start-Sleep 10

# Try to create SIP trunk
Write-Host "Creating SIP Trunk..." -ForegroundColor Yellow
try {
    $trunkResult = & livekit-cli create-sip-trunk --url $env:LIVEKIT_URL --api-key $env:LIVEKIT_API_KEY --api-secret $env:LIVEKIT_API_SECRET --request sip-trunk.json 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ SIP Trunk: Created successfully" -ForegroundColor Green
        Write-Host $trunkResult
    } else {
        Write-Host "⚠️  SIP Trunk: Creation failed" -ForegroundColor Yellow
        Write-Host "Error: $trunkResult" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ SIP Trunk: Creation error" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

# Try to create dispatch rule
Write-Host "Creating SIP Dispatch Rule..." -ForegroundColor Yellow
try {
    $dispatchResult = & livekit-cli create-sip-dispatch-rule --url $env:LIVEKIT_URL --api-key $env:LIVEKIT_API_KEY --api-secret $env:LIVEKIT_API_SECRET --request sip-dispatch-rule.json 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ SIP Dispatch Rule: Created successfully" -ForegroundColor Green
        Write-Host $dispatchResult
    } else {
        Write-Host "⚠️  SIP Dispatch Rule: Creation failed" -ForegroundColor Yellow
        Write-Host "Error: $dispatchResult" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ SIP Dispatch Rule: Creation error" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

Write-Host ""
Write-Host "=== Setup Summary ===" -ForegroundColor Cyan
Write-Host "LiveKit Server: http://localhost:7880"
Write-Host "SIP Service: localhost:5060"
Write-Host "Test Room: sip-test-room"
Write-Host "API Key: API5DcPxqyBDHLr"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Configure your SIP provider to point to this server"
Write-Host "2. Test inbound calls to configured numbers"
Write-Host "3. Test outbound calls using LiveKit SDK"
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")