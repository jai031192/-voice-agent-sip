# Connect to running container and create trunk/dispatch
# This script connects to your running LiveKit SIP container and creates the configuration

Write-Host "🐳 Connecting to LiveKit SIP container..." -ForegroundColor Green

# Configuration
$SERVER_IP = "your-server-ip"                # Update with your server IP
$CONTAINER_NAME = "livekit-sip-deployment-sip-1"  # Update if different
$TWILIO_NUMBER = "+13074606119"

Write-Host "📋 Configuration:" -ForegroundColor Cyan
Write-Host "  Server IP: $SERVER_IP"
Write-Host "  Container: $CONTAINER_NAME"
Write-Host "  Twilio Number: $TWILIO_NUMBER"
Write-Host ""

# Check if we can connect to the server
Write-Host "🔍 Checking server connection..." -ForegroundColor Yellow
try {
    $response = Test-NetConnection -ComputerName $SERVER_IP -Port 22 -WarningAction SilentlyContinue
    if ($response.TcpTestSucceeded) {
        Write-Host "✅ Server is reachable on port 22 (SSH)" -ForegroundColor Green
    } else {
        Write-Host "❌ Cannot reach server on SSH port. You may need VPN or different connection method." -ForegroundColor Red
    }
} catch {
    Write-Host "⚠️ Network test failed, but server might still be accessible" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📝 Docker commands to run on your server:" -ForegroundColor Cyan
Write-Host ""

$commands = @"
# First, SSH to your server and run these commands:
ssh your-username@$SERVER_IP

# Navigate to the project directory
cd /path/to/your/sip/project/livekit-sip-deployment

# Check if containers are running
docker ps | grep livekit

# Connect to the SIP container
docker exec -it $CONTAINER_NAME /bin/bash

# Inside the container, set environment variables
export LIVEKIT_URL="http://localhost:7880"
export LIVEKIT_API_KEY="your-api-key"
export LIVEKIT_API_SECRET="your-api-secret"

# Create trunk JSON
cat > /tmp/trunk.json << 'EOF'
{
  "sip_trunk_id": "twilio-trunk-001",
  "kind": "TRUNK_OUTBOUND",
  "inbound_addresses": [],
  "outbound_address": "sip.twilio.com",
  "outbound_number": "$TWILIO_NUMBER",
  "inbound_numbers_regex": [],
  "inbound_numbers": ["$TWILIO_NUMBER"],
  "inbound_username": "",
  "inbound_password": "",
  "outbound_username": "your-twilio-username",
  "outbound_password": "your-twilio-password",
  "name": "Twilio SIP Trunk",
  "metadata": ""
}
EOF

# Create dispatch JSON
cat > /tmp/dispatch.json << 'EOF'
{
  "dispatch_rule_id": "twilio-dispatch-individual",
  "rule": {
    "dispatchRuleIndividual": {
      "roomPrefix": "call-",
      "pin": "",
      "roomConfig": {
        "name": "",
        "emptyTimeout": 300,
        "maxParticipants": 10,
        "metadata": ""
      }
    }
  },
  "trunk_ids": ["twilio-trunk-001"],
  "hidePhoneNumber": false,
  "inboundNumbers": ["$TWILIO_NUMBER"],
  "name": "Individual Room Dispatch",
  "metadata": ""
}
EOF

# Test which CLI command works
lk --version
# or
livekit-cli --version

# Try creating trunk (use the command that works from above)
lk sip create-sip-trunk --from-file /tmp/trunk.json
# or if above fails:
lk sip trunk create --from-file /tmp/trunk.json
# or if using old CLI:
livekit-cli create-sip-trunk --from-file /tmp/trunk.json

# Try creating dispatch rule
lk sip create-sip-dispatch-rule --from-file /tmp/dispatch.json
# or if above fails:
lk sip dispatch create --from-file /tmp/dispatch.json
# or if using old CLI:
livekit-cli create-sip-dispatch-rule --from-file /tmp/dispatch.json

# List created resources
lk sip list-sip-trunk
lk sip list-sip-dispatch-rule

# Exit container
exit
"@

Write-Host $commands -ForegroundColor White

Write-Host ""
Write-Host "💾 Saving commands to file..." -ForegroundColor Yellow
$commandsFile = "C:\Users\ravik\OneDrive\Desktop\SIP SERVER\sip\server-commands.txt"
$commands | Out-File -FilePath $commandsFile -Encoding UTF8
Write-Host "✅ Commands saved to: $commandsFile" -ForegroundColor Green

Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Copy the commands from $commandsFile" -ForegroundColor White
Write-Host "2. SSH to your server and run them" -ForegroundColor White
Write-Host "3. Update the Twilio credentials in the JSON files" -ForegroundColor White
Write-Host "4. Test the trunk and dispatch creation" -ForegroundColor White