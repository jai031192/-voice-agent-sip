# Create SIP Trunk and Dispatch via HTTP API from Windows
# This script uses PowerShell to make direct HTTP API calls to your LiveKit server

Write-Host "🌐 Creating SIP Trunk and Dispatch via HTTP API..." -ForegroundColor Green

# Configuration - UPDATE THESE VALUES
$LIVEKIT_URL = "https://your-server-ip:7880"  # Update with your actual server IP
$LIVEKIT_API_KEY = "your-api-key"             # Update with your actual API key
$LIVEKIT_API_SECRET = "your-api-secret"       # Update with your actual API secret
$TWILIO_NUMBER = "+13074606119"               # Your Twilio number

Write-Host "📋 Configuration:" -ForegroundColor Cyan
Write-Host "  LiveKit URL: $LIVEKIT_URL"
Write-Host "  API Key: $LIVEKIT_API_KEY"
Write-Host "  Twilio Number: $TWILIO_NUMBER"
Write-Host ""

# Function to generate JWT token for LiveKit API
function New-LiveKitToken {
    param(
        [string]$ApiKey,
        [string]$ApiSecret,
        [int]$ExpirationMinutes = 60
    )
    
    # For now, we'll create a simple approach
    # In production, you'd want proper JWT generation
    Write-Host "⚠️ For HTTP API calls, you need to generate a proper JWT token" -ForegroundColor Yellow
    Write-Host "This requires JWT libraries. Using CLI or container method is recommended." -ForegroundColor Yellow
    return $null
}

# Create trunk JSON payload
$trunkPayload = @{
    "sip_trunk_id" = "twilio-trunk-001"
    "kind" = "TRUNK_OUTBOUND"
    "inbound_addresses" = @()
    "outbound_address" = "sip.twilio.com"
    "outbound_number" = $TWILIO_NUMBER
    "inbound_numbers_regex" = @()
    "inbound_numbers" = @($TWILIO_NUMBER)
    "inbound_username" = ""
    "inbound_password" = ""
    "outbound_username" = "your-twilio-username"  # UPDATE THIS
    "outbound_password" = "your-twilio-password"  # UPDATE THIS
    "name" = "Twilio SIP Trunk"
    "metadata" = ""
} | ConvertTo-Json -Depth 10

# Create dispatch JSON payload
$dispatchPayload = @{
    "dispatch_rule_id" = "twilio-dispatch-individual"
    "rule" = @{
        "dispatchRuleIndividual" = @{
            "roomPrefix" = "call-"
            "pin" = ""
            "roomConfig" = @{
                "name" = ""
                "emptyTimeout" = 300
                "maxParticipants" = 10
                "metadata" = ""
            }
        }
    }
    "trunk_ids" = @("twilio-trunk-001")
    "hidePhoneNumber" = $false
    "inboundNumbers" = @($TWILIO_NUMBER)
    "name" = "Individual Room Dispatch"
    "metadata" = ""
} | ConvertTo-Json -Depth 10

Write-Host "📝 Trunk JSON:" -ForegroundColor Cyan
Write-Host $trunkPayload

Write-Host ""
Write-Host "📝 Dispatch JSON:" -ForegroundColor Cyan
Write-Host $dispatchPayload

Write-Host ""
Write-Host "🔧 API Endpoints:" -ForegroundColor Yellow
Write-Host "  Create Trunk: POST $LIVEKIT_URL/twirp/livekit.SIPService/CreateSIPTrunk"
Write-Host "  Create Dispatch: POST $LIVEKIT_URL/twirp/livekit.SIPService/CreateSIPDispatchRule"
Write-Host "  List Trunks: POST $LIVEKIT_URL/twirp/livekit.SIPService/ListSIPTrunk"
Write-Host "  List Dispatch: POST $LIVEKIT_URL/twirp/livekit.SIPService/ListSIPDispatchRule"

Write-Host ""
Write-Host "💡 Recommendation:" -ForegroundColor Green
Write-Host "For simplicity, use one of these methods instead:" -ForegroundColor White
Write-Host "1. Install LiveKit CLI on Windows (install-livekit-cli-windows.ps1)" -ForegroundColor White
Write-Host "2. Connect to your running container (connect-to-container.ps1)" -ForegroundColor White
Write-Host ""
Write-Host "HTTP API requires proper JWT token generation which is complex in PowerShell." -ForegroundColor Yellow

# Save payloads to files for reference
$trunkFile = "C:\Users\ravik\OneDrive\Desktop\SIP SERVER\sip\trunk-payload.json"
$dispatchFile = "C:\Users\ravik\OneDrive\Desktop\SIP SERVER\sip\dispatch-payload.json"

$trunkPayload | Out-File -FilePath $trunkFile -Encoding UTF8
$dispatchPayload | Out-File -FilePath $dispatchFile -Encoding UTF8

Write-Host "💾 JSON payloads saved:" -ForegroundColor Green
Write-Host "  Trunk: $trunkFile"
Write-Host "  Dispatch: $dispatchFile"

# Generate curl commands for reference
$curlCommands = @"
# Use these curl commands on your server or in a Linux environment:

# Create SIP Trunk
curl -X POST '$LIVEKIT_URL/twirp/livekit.SIPService/CreateSIPTrunk' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -d '$($trunkPayload -replace "`n", "" -replace "`r", "")'

# Create Dispatch Rule  
curl -X POST '$LIVEKIT_URL/twirp/livekit.SIPService/CreateSIPDispatchRule' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -d '$($dispatchPayload -replace "`n", "" -replace "`r", "")'

# List SIP Trunks
curl -X POST '$LIVEKIT_URL/twirp/livekit.SIPService/ListSIPTrunk' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -d '{}'

# List Dispatch Rules
curl -X POST '$LIVEKIT_URL/twirp/livekit.SIPService/ListSIPDispatchRule' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -d '{}'
"@

$curlFile = "C:\Users\ravik\OneDrive\Desktop\SIP SERVER\sip\curl-commands.txt"
$curlCommands | Out-File -FilePath $curlFile -Encoding UTF8

Write-Host ""
Write-Host "📋 cURL commands saved to: $curlFile" -ForegroundColor Green
Write-Host "You can use these on your server with proper JWT token" -ForegroundColor Cyan