#!/bin/bash
set -e

echo "===========================================" 
echo "🔧 TWILIO SIP TRUNK SETUP STARTING"
echo "===========================================" 
echo "Setting up Twilio SIP Trunk and Dispatch Rule..."

# Wait for LiveKit server to be ready
echo "Waiting for LiveKit server to start..."
timeout=60
while [ $timeout -gt 0 ]; do
    if curl -s http://localhost:7880/health > /dev/null 2>&1; then
        echo "✅ LiveKit server is ready!"
        break
    fi
    echo "⏳ Waiting for LiveKit server... ($timeout seconds remaining)"
    sleep 2
    timeout=$((timeout - 2))
done

if [ $timeout -le 0 ]; then
    echo "❌ ERROR: LiveKit server failed to start within 60 seconds"
    exit 1
fi

# Additional wait to ensure all services are stable
echo "⏳ Waiting additional 10 seconds for services to stabilize..."
sleep 10

# Set up LiveKit CLI environment
export LIVEKIT_URL="http://localhost:7880"
export LIVEKIT_API_KEY="${LIVEKIT_API_KEY:-API5DcPxqyBDHLr}"
export LIVEKIT_API_SECRET="${LIVEKIT_API_SECRET:-b9dgi6VEHsXf1zLKFWffHONECta5Xvfs5ejgdZhUoxPE}"

echo "🔑 Using API Key: $LIVEKIT_API_KEY"
echo "🌐 LiveKit URL: $LIVEKIT_URL"

echo "📞 Creating Twilio inbound SIP trunk..."

# Prepare the authorization header
AUTH_HEADER="Authorization: Bearer $(echo -n "${LIVEKIT_API_KEY}:${LIVEKIT_API_SECRET}" | base64)"
echo "🔐 Authorization header prepared"

# Create the inbound trunk
echo "📡 Making API call to create trunk..."
TRUNK_RESPONSE=$(curl -v -X POST "http://localhost:7880/twirp/livekit.SIP/CreateSIPInboundTrunk" \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER" \
  -d '{
    "trunk": {
      "name": "Twilio Inbound Trunk",
      "inbound_addresses": [],
      "inbound_numbers": ["+13074606119"],
      "inbound_username": "",
      "inbound_password": "",
      "metadata": "provider=Twilio,number=+13074606119,type=inbound"
    }
  }' 2>&1)

echo "📋 Trunk creation response:"
echo "$TRUNK_RESPONSE"
echo ""

if echo "$TRUNK_RESPONSE" | grep -q "sip_trunk_id"; then
    TRUNK_ID=$(echo "$TRUNK_RESPONSE" | grep -o '"sip_trunk_id":"[^"]*"' | cut -d'"' -f4)
    echo "✅ Twilio trunk created successfully with ID: $TRUNK_ID"
    
    echo "📋 Creating dispatch rule for Twilio trunk..."
    
    # Create the dispatch rule
    echo "📡 Making API call to create dispatch rule..."
    RULE_RESPONSE=$(curl -v -X POST "http://localhost:7880/twirp/livekit.SIP/CreateSIPDispatchRule" \
      -H "Content-Type: application/json" \
      -H "$AUTH_HEADER" \
      -d "{
        \"rule\": {
          \"dispatch_rule_direct\": {
            \"room_name\": \"twilio-test-room\"
          }
        },
        \"trunk_ids\": [\"$TRUNK_ID\"],
        \"hide_phone_number\": false,
        \"metadata\": \"test=true,provider=Twilio\"
      }" 2>&1)
    
    echo "📋 Dispatch rule creation response:"
    echo "$RULE_RESPONSE"
    echo ""
    
    if echo "$RULE_RESPONSE" | grep -q "sip_dispatch_rule_id"; then
        RULE_ID=$(echo "$RULE_RESPONSE" | grep -o '"sip_dispatch_rule_id":"[^"]*"' | cut -d'"' -f4)
        echo "✅ Dispatch rule created successfully with ID: $RULE_ID"
        echo ""
        echo "🎉 TWILIO SIP CONFIGURATION COMPLETE!"
        echo "====================================="
        echo "📞 Inbound number: +1 307 460 6119"
        echo "🏠 Target room: twilio-test-room"
        echo "🆔 Trunk ID: $TRUNK_ID"
        echo "📋 Rule ID: $RULE_ID"
        echo "📍 SIP URI: sip:+13074606119@${EXTERNAL_IP}:5170"
        echo ""
        echo "✅ You can now configure Twilio to send calls to this endpoint!"
        echo "====================================="
    else
        echo "❌ FAILED to create dispatch rule"
        echo "Response: $RULE_RESPONSE"
        exit 1
    fi
else
    echo "❌ FAILED to create Twilio trunk"
    echo "Response: $TRUNK_RESPONSE"
    exit 1
fi

echo "🏁 Twilio setup script completed successfully."