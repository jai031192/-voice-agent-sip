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

# Check available CLI commands
echo "🔍 Checking for LiveKit CLI..."
if command -v livekit-cli > /dev/null 2>&1; then
    echo "✅ LiveKit CLI found, checking available commands..."
    
    # Debug: Show CLI help
    echo "📋 Available CLI commands:"
    livekit-cli --help | head -20
    
    echo ""
    echo "🔍 Looking for SIP-related commands:"
    livekit-cli --help | grep -i sip || echo "No SIP commands found in main help"
    
    # Check if there's a sip subcommand
    echo ""
    echo "🔍 Checking for 'sip' subcommand:"
    livekit-cli sip --help 2>&1 | head -10 || echo "No 'sip' subcommand found"
    
    # Try to create trunk with different command formats
    echo ""
    echo "📞 Attempting to create Twilio inbound trunk..."
    
    # Try format 1: Direct API approach
    echo "🔄 Trying HTTP API approach..."
    TRUNK_RESPONSE=$(curl -s -X POST http://localhost:7880/twirp/livekit.SIP/CreateSIPInboundTrunk \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $(echo -n "${LIVEKIT_API_KEY}:${LIVEKIT_API_SECRET}" | base64)" \
        -d '{
            "trunk": {
                "name": "Twilio Inbound Trunk",
                "inbound_numbers": ["+13074606119"],
                "metadata": "provider=Twilio,number=+13074606119,type=inbound"
            }
        }' 2>&1 || echo "HTTP API failed")
    
    echo "📋 HTTP API response:"
    echo "$TRUNK_RESPONSE"
    
    if echo "$TRUNK_RESPONSE" | grep -q "sipTrunkId"; then
        TRUNK_ID=$(echo "$TRUNK_RESPONSE" | jq -r '.sipTrunkId' 2>/dev/null || echo "ID_EXTRACTION_FAILED")
        echo "✅ Trunk created via HTTP API with ID: $TRUNK_ID"
        
        # Create dispatch rule
        echo "📋 Creating dispatch rule..."
        RULE_RESPONSE=$(curl -s -X POST http://localhost:7880/twirp/livekit.SIP/CreateSIPDispatchRule \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $(echo -n "${LIVEKIT_API_KEY}:${LIVEKIT_API_SECRET}" | base64)" \
            -d "{
                \"rule\": {
                    \"dispatchRuleDirect\": {
                        \"roomName\": \"twilio-test-room\"
                    }
                },
                \"trunkIds\": [\"$TRUNK_ID\"],
                \"hidePhoneNumber\": false,
                \"metadata\": \"test=true,provider=Twilio\"
            }" 2>&1)
        
        echo "📋 Rule creation response:"
        echo "$RULE_RESPONSE"
        
        if echo "$RULE_RESPONSE" | grep -q "sipDispatchRuleId"; then
            RULE_ID=$(echo "$RULE_RESPONSE" | jq -r '.sipDispatchRuleId' 2>/dev/null || echo "RULE_ID_EXTRACTION_FAILED")
            echo "✅ Dispatch rule created with ID: $RULE_ID"
            
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
            echo "❌ Failed to create dispatch rule"
            echo "Response: $RULE_RESPONSE"
            exit 1
        fi
    else
        echo "❌ Failed to create trunk via HTTP API"
        echo "Response: $TRUNK_RESPONSE"
        
        # Try alternative approaches
        echo ""
        echo "🔄 Attempting alternative CLI commands..."
        
        # List available CLI commands for debugging
        echo "Available CLI commands:"
        livekit-cli --help | grep -E "^\s*[a-z]" || echo "No commands found"
        
        exit 1
    fi
else
    echo "❌ LiveKit CLI not found"
    echo "ℹ️  You will need to create the trunk and dispatch rule manually:"
    echo "   1. Trunk for number: +13074606119"
    echo "   2. Dispatch rule to room: twilio-test-room"
    exit 0
fi

echo "🏁 Twilio setup script completed successfully."