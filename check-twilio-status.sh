#!/bin/bash

echo "🔍 Checking Twilio SIP Trunk Status"
echo "=================================="

# Check if container is running
if ! docker ps | grep -q "voice-agent-sip-container"; then
    echo "❌ Container 'voice-agent-sip-container' is not running"
    echo "Please start it first with:"
    echo "docker run -d --name voice-agent-sip-container -p 5170:5170 -p 8080:8080 voice-agent-sip:latest"
    exit 1
fi

echo "✅ Container is running"

# Get API credentials from environment or use defaults
LIVEKIT_API_KEY="API5DcPxqyBDHLr"
LIVEKIT_API_SECRET="b9dgi6VEHsXf1zLKFWffHONECta5Xvfs5ejgdZhUoxPE"

echo "🔑 Using API Key: $LIVEKIT_API_KEY"

# Check health
echo ""
echo "🏥 Checking service health..."
if curl -s http://localhost:8080/health > /dev/null; then
    echo "✅ Health endpoint responding"
else
    echo "❌ Health endpoint not responding"
    exit 1
fi

# List inbound trunks
echo ""
echo "📞 Checking inbound SIP trunks..."
AUTH_HEADER="Authorization: Bearer $(echo -n "${LIVEKIT_API_KEY}:${LIVEKIT_API_SECRET}" | base64)"

TRUNKS_RESPONSE=$(curl -s -X POST "http://localhost:8080/twirp/livekit.SIP/ListSIPInboundTrunk" \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER" \
  -d '{}')

echo "📋 Trunks Response:"
echo "$TRUNKS_RESPONSE" | jq '.' 2>/dev/null || echo "$TRUNKS_RESPONSE"

# List dispatch rules
echo ""
echo "📋 Checking dispatch rules..."
RULES_RESPONSE=$(curl -s -X POST "http://localhost:8080/twirp/livekit.SIP/ListSIPDispatchRule" \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER" \
  -d '{}')

echo "📋 Rules Response:"
echo "$RULES_RESPONSE" | jq '.' 2>/dev/null || echo "$RULES_RESPONSE"

echo ""
echo "🔗 If trunks exist, configure Twilio to point to:"
echo "📍 sip:+13074606119@40.81.229.194:5170"