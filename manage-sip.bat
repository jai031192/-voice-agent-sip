@echo off
echo LiveKit SIP Management Script
echo ============================
echo.

set LIVEKIT_URL=http://localhost:7880
set LIVEKIT_API_KEY=108378f337bbab3ce4e944554bed555a
set LIVEKIT_API_SECRET=2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d

echo Environment:
echo - Server: %LIVEKIT_URL%
echo - API Key: %LIVEKIT_API_KEY%
echo.

:menu
echo Select an option:
echo 1. Create SIP Trunk
echo 2. Create Dispatch Rule  
echo 3. List SIP Trunks
echo 4. List Dispatch Rules
echo 5. Test Room Creation
echo 6. Exit
echo.
set /p choice="Enter choice (1-6): "

if "%choice%"=="1" goto create_trunk
if "%choice%"=="2" goto create_dispatch
if "%choice%"=="3" goto list_trunks
if "%choice%"=="4" goto list_dispatch
if "%choice%"=="5" goto test_room
if "%choice%"=="6" goto exit

:create_trunk
echo Creating SIP Trunk...
livekit-cli create-sip-trunk --url %LIVEKIT_URL% --api-key %LIVEKIT_API_KEY% --api-secret %LIVEKIT_API_SECRET% --request sip-trunk.json
pause
goto menu

:create_dispatch
echo Creating Dispatch Rule...
livekit-cli create-sip-dispatch-rule --url %LIVEKIT_URL% --api-key %LIVEKIT_API_KEY% --api-secret %LIVEKIT_API_SECRET% --request sip-dispatch-rule.json
pause
goto menu

:list_trunks
echo Listing SIP Trunks...
livekit-cli list-sip-trunk --url %LIVEKIT_URL% --api-key %LIVEKIT_API_KEY% --api-secret %LIVEKIT_API_SECRET%
pause
goto menu

:list_dispatch
echo Listing Dispatch Rules...
livekit-cli list-sip-dispatch-rule --url %LIVEKIT_URL% --api-key %LIVEKIT_API_KEY% --api-secret %LIVEKIT_API_SECRET%
pause
goto menu

:test_room
echo Creating test room...
livekit-cli create-room --url %LIVEKIT_URL% --api-key %LIVEKIT_API_KEY% --api-secret %LIVEKIT_API_SECRET% --name sip-test-room
pause
goto menu

:exit
echo Goodbye!
exit