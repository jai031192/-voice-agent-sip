# Create SIP Inbound Trunk and Dispatch Rule using LiveKit Cloud
# Updated with LiveKit Cloud credentials for reliable testing

Write-Host "Creating SIP Inbound Trunk and Dispatch Rule using LiveKit Cloud..." -ForegroundColor Green

# Configuration - LiveKit Cloud credentials
$LIVEKIT_URL = "wss://neurogentdemo-s3ds5s3w.livekit.cloud"
$LIVEKIT_API_KEY = "APIYYjaZoJZyTda"
$LIVEKIT_API_SECRET = "I16e53PBD7ROg0bw9LymVegUEyqe6qGVa8yUNlp8oJ4B"
$PHONE_NUMBER = "+919240908080"               # Your MONKHUB phone number
$SIP_SERVER = "27.107.220.6"                 # Your SIP SBC IP
$SIP_USERNAME = "00919240908080"              # Your SIP username
$SIP_PASSWORD = "1234"                       # Your SIP password

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  LiveKit URL: $LIVEKIT_URL"
Write-Host "  Phone Number: $PHONE_NUMBER"
Write-Host "  SIP Server: $SIP_SERVER"
Write-Host ""

# Check if CLI is installed
try {
    $version = & lk --version 2>&1
    Write-Host "LiveKit CLI found: $version" -ForegroundColor Green
} catch {
    Write-Host "LiveKit CLI not found. Please install it first." -ForegroundColor Red
    exit 1
}

# Set environment variables
$env:LIVEKIT_URL = $LIVEKIT_URL
$env:LIVEKIT_API_KEY = $LIVEKIT_API_KEY
$env:LIVEKIT_API_SECRET = $LIVEKIT_API_SECRET

Write-Host "Environment variables set for LiveKit Cloud" -ForegroundColor Yellow

# Test connection to LiveKit Cloud
Write-Host "Testing connection to LiveKit Cloud..." -ForegroundColor Yellow
try {
    $testResult = & lk token create --identity test-user 2>&1
    if ($testResult -like "*token*" -or $testResult -like "*eyJ*") {
        Write-Host "Connection to LiveKit Cloud successful!" -ForegroundColor Green
    } else {
        Write-Host "Connection test result: $testResult" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Connection test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Creating SIP Inbound Trunk..." -ForegroundColor Green

# Create inbound trunk using proper CLI syntax
try {
    $trunkResult = & lk sip inbound create `
        --trunk-id "monkhub-inbound-trunk-001" `
        --name "MONKHUB Inbound SIP Trunk" `
        --number $PHONE_NUMBER `
        --allowed-address $SIP_SERVER `
        --username $SIP_USERNAME `
        --password $SIP_PASSWORD 2>&1
    
    Write-Host "Inbound trunk creation result:" -ForegroundColor Green
    Write-Host $trunkResult
    
    if ($trunkResult -like "*created*" -or $trunkResult -like "*success*") {
        Write-Host "Trunk created successfully!" -ForegroundColor Green
        $trunkCreated = $true
    } else {
        Write-Host "Trunk creation may have failed. Check output above." -ForegroundColor Yellow
        $trunkCreated = $false
    }
} catch {
    Write-Host "Trunk creation failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    $trunkCreated = $false
}

Write-Host ""
Write-Host "Creating Dispatch Rule..." -ForegroundColor Green

# Create dispatch rule using proper CLI syntax
try {
    $dispatchResult = & lk sip dispatch create `
        --rule-id "monkhub-dispatch-individual" `
        --name "Individual Room Dispatch" `
        --trunk-id "monkhub-inbound-trunk-001" `
        --number $PHONE_NUMBER `
        --room-prefix "call-" `
        --pin "" 2>&1
    
    Write-Host "Dispatch rule creation result:" -ForegroundColor Green
    Write-Host $dispatchResult
    
    if ($dispatchResult -like "*created*" -or $dispatchResult -like "*success*") {
        Write-Host "Dispatch rule created successfully!" -ForegroundColor Green
        $dispatchCreated = $true
    } else {
        Write-Host "Dispatch rule creation may have failed. Check output above." -ForegroundColor Yellow
        $dispatchCreated = $false
    }
} catch {
    Write-Host "Dispatch rule creation failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    $dispatchCreated = $false
}

Write-Host ""
Write-Host "Listing existing trunks and dispatch rules..." -ForegroundColor Cyan

# List inbound trunks
try {
    Write-Host "SIP Inbound Trunks:" -ForegroundColor Yellow
    $trunkList = & lk sip inbound list 2>&1
    Write-Host $trunkList
} catch {
    Write-Host "Could not list inbound trunks: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# List dispatch rules
try {
    Write-Host "SIP Dispatch Rules:" -ForegroundColor Yellow
    $dispatchList = & lk sip dispatch list 2>&1
    Write-Host $dispatchList
} catch {
    Write-Host "Could not list dispatch rules: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
if ($trunkCreated) {
    Write-Host "✅ Inbound Trunk: Created successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Inbound Trunk: Creation failed" -ForegroundColor Red
}

if ($dispatchCreated) {
    Write-Host "✅ Dispatch Rule: Created successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Dispatch Rule: Creation failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "Script completed!" -ForegroundColor Green
Write-Host "Your SIP configuration should now be ready for testing calls to $PHONE_NUMBER" -ForegroundColor Cyan