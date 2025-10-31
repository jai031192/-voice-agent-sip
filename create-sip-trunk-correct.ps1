# Create INBOUND SIP Trunk and Dispatch Rule - Correct CLI Syntax
Write-Host "Creating INBOUND SIP Trunk and Dispatch Rule..." -ForegroundColor Green

# Configuration
$LIVEKIT_URL = "http://40.81.229.194:7880"
$LIVEKIT_API_KEY = "108378f337bbab3ce4e944554bed555a"
$LIVEKIT_API_SECRET = "2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d"
$PHONE_NUMBER = "+919240908080"
$SIP_USERNAME = "00919240908080"
$SIP_PASSWORD = "1234"
$TRUNK_NAME = "monkhub-inbound-trunk-001"

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  LiveKit URL: $LIVEKIT_URL"
Write-Host "  Phone Number: $PHONE_NUMBER"
Write-Host "  SIP Username: $SIP_USERNAME"
Write-Host "  Trunk Name: $TRUNK_NAME"
Write-Host ""

# Set environment variables
$env:LIVEKIT_URL = $LIVEKIT_URL
$env:LIVEKIT_API_KEY = $LIVEKIT_API_KEY
$env:LIVEKIT_API_SECRET = $LIVEKIT_API_SECRET

Write-Host "Step 1: Creating INBOUND SIP Trunk..." -ForegroundColor Yellow
try {
    $trunkResult = & lk sip inbound create --name $TRUNK_NAME --numbers $PHONE_NUMBER --auth-user $SIP_USERNAME --auth-pass $SIP_PASSWORD 2>&1
    Write-Host "Trunk Creation Result:" -ForegroundColor Green
    Write-Host $trunkResult
    Write-Host ""
} catch {
    Write-Host "Trunk creation failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host ""
}

Write-Host "Step 2: Creating Dispatch Rule for Individual Rooms..." -ForegroundColor Yellow
try {
    $dispatchResult = & lk sip dispatch create --name "individual-room-dispatch" --trunks $TRUNK_NAME --individual "call-" 2>&1
    Write-Host "Dispatch Creation Result:" -ForegroundColor Green
    Write-Host $dispatchResult
    Write-Host ""
} catch {
    Write-Host "Dispatch creation failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host ""
}

Write-Host "Step 3: Listing existing trunks..." -ForegroundColor Yellow
try {
    Write-Host "Inbound SIP Trunks:" -ForegroundColor Cyan
    & lk sip inbound list 2>&1 | Write-Host
    Write-Host ""
} catch {
    Write-Host "Could not list inbound trunks" -ForegroundColor Red
    Write-Host ""
}

Write-Host "Step 4: Listing existing dispatch rules..." -ForegroundColor Yellow
try {
    Write-Host "Dispatch Rules:" -ForegroundColor Cyan
    & lk sip dispatch list 2>&1 | Write-Host
    Write-Host ""
} catch {
    Write-Host "Could not list dispatch rules" -ForegroundColor Red
    Write-Host ""
}

Write-Host "Script completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "- Trunk Name: $TRUNK_NAME"
Write-Host "- Phone Number: $PHONE_NUMBER" 
Write-Host "- Dispatch: Individual rooms with prefix 'call-'"
Write-Host ""
Write-Host "If there were connection errors, make sure:" -ForegroundColor Yellow
Write-Host "1. Your LiveKit server is running on $LIVEKIT_URL"
Write-Host "2. The API credentials are correct"
Write-Host "3. Port 7880 is accessible from your computer"