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

# Check if LiveKit CLI is available
echo "� Checking for LiveKit CLI..."
if command -v livekit-cli > /dev/null 2>&1; then
    echo "✅ LiveKit CLI found, using CLI approach"
    
    # Create trunk using CLI
    echo "� Creating Twilio inbound trunk using CLI..."
    cat > /tmp/trunk.json << EOF
{
  "trunk": {
    "name": "Twilio Inbound Trunk",
    "inbound_addresses": [],
    "inbound_numbers": ["+13074606119"],
    "inbound_username": "",
    "inbound_password": "",
    "metadata": "provider=Twilio,number=+13074606119,type=inbound"
  }
}
EOF

    TRUNK_RESPONSE=$(livekit-cli create-sip-inbound-trunk --request /tmp/trunk.json 2>&1)
    echo "📋 CLI Trunk creation response:"
    echo "$TRUNK_RESPONSE"
    
    if echo "$TRUNK_RESPONSE" | grep -q "SIP Trunk ID"; then
        TRUNK_ID=$(echo "$TRUNK_RESPONSE" | grep "SIP Trunk ID" | awk '{print $NF}')
        echo "✅ Twilio trunk created successfully with ID: $TRUNK_ID"
        
        # Create dispatch rule using CLI
        echo "� Creating dispatch rule using CLI..."
        cat > /tmp/rule.json << EOF
{
  "rule": {
    "dispatch_rule_direct": {
      "room_name": "twilio-test-room"
    }
  },
  "trunk_ids": ["$TRUNK_ID"],
  "hide_phone_number": false,
  "metadata": "test=true,provider=Twilio"
}
EOF

        RULE_RESPONSE=$(livekit-cli create-sip-dispatch-rule --request /tmp/rule.json 2>&1)
        echo "📋 CLI Rule creation response:"
        echo "$RULE_RESPONSE"
        
        if echo "$RULE_RESPONSE" | grep -q "SIP Dispatch Rule ID"; then
            RULE_ID=$(echo "$RULE_RESPONSE" | grep "SIP Dispatch Rule ID" | awk '{print $NF}')
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
            echo "❌ FAILED to create dispatch rule using CLI"
            echo "Response: $RULE_RESPONSE"
            exit 1
        fi
    else
        echo "❌ FAILED to create Twilio trunk using CLI"
        echo "Response: $TRUNK_RESPONSE"
        exit 1
    fi
else
    echo "❌ LiveKit CLI not found, skipping automatic trunk creation"
    echo "ℹ️  You will need to create the trunk and dispatch rule manually:"
    echo "   1. Trunk for number: +13074606119"
    echo "   2. Dispatch rule to room: twilio-test-room"
    exit 0
fi

echo "🏁 Twilio setup script completed successfully."