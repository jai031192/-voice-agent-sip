@echo off
echo Starting LiveKit SIP Service Test Environment...
echo.

REM Check if Redis is running
echo [1/4] Checking Redis...
redis\redis-cli.exe ping >nul 2>&1
if %errorlevel% neq 0 (
    echo Starting Redis server...
    start /B redis\redis-server.exe
    timeout /t 3 >nul
)
echo Redis: OK

REM Check if LiveKit server is running
echo [2/4] Checking LiveKit Server...
curl -s http://localhost:7880 >nul 2>&1
if %errorlevel% neq 0 (
    echo Starting LiveKit server...
    start livekit\livekit-server.exe --config livekit-config.yaml
    timeout /t 5 >nul
)
echo LiveKit Server: OK

REM Start SIP service
echo [3/4] Starting SIP Service...
echo SIP Service starting on port 5060...
echo.

REM Display connection info
echo [4/4] Service Information:
echo ================================
echo LiveKit Server: http://localhost:7880
echo SIP Service: 0.0.0.0:5060
echo Redis: localhost:6379
echo API Key: 108378f337bbab3ce4e944554bed555a
echo ================================
echo.
echo Starting SIP service... (Press Ctrl+C to stop)

sip.exe --config config.yaml