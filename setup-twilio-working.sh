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
export LIVEKIT_API_KEY="${LIVEKIT_API_KEY:-108378f337bbab3ce4e944554bed555a}"
export LIVEKIT_API_SECRET="${LIVEKIT_API_SECRET:-2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d}"

echo "🔑 Using API Key: $LIVEKIT_API_KEY"
echo "🌐 LiveKit URL: $LIVEKIT_URL"

echo "📞 Creating Twilio inbound trunk using correct CLI syntax..."

# Create the trunk JSON file as expected by the CLI
cat > /tmp/create_trunk.json << EOF
{
  "trunk": {
    "name": "Twilio Inbound Trunk",
    "inbound_numbers": ["+13074606119"],
    "metadata": "provider=Twilio,number=+13074606119,type=inbound"
  }
}
EOF

echo "📋 Trunk configuration JSON:"
cat /tmp/create_trunk.json

# Create the trunk using CLI with JSON file
echo ""
echo "🔄 Creating trunk with JSON file input..."
TRUNK_RESPONSE=$(livekit-cli sip inbound create /tmp/create_trunk.json 2>&1)

echo "📋 Trunk creation response:"
echo "$TRUNK_RESPONSE"

# Check if trunk creation was successful and extract ID
if echo "$TRUNK_RESPONSE" | grep -qi "trunk.*created\|sipTrunkId\|success"; then
    echo "✅ Trunk creation succeeded!"
    
    # Try to extract trunk ID from response
    TRUNK_ID=$(echo "$TRUNK_RESPONSE" | grep -oE "[a-zA-Z0-9_-]{20,}" | head -1)
    if [ -z "$TRUNK_ID" ]; then
        # Alternative ID extraction
        TRUNK_ID=$(echo "$TRUNK_RESPONSE" | jq -r '.sipTrunkId' 2>/dev/null || echo "ID_EXTRACTION_FAILED")
    fi
    
    echo "🆔 Extracted Trunk ID: $TRUNK_ID"
    
    if [ "$TRUNK_ID" != "ID_EXTRACTION_FAILED" ] && [ ! -z "$TRUNK_ID" ]; then
        # Now create dispatch rule
        echo ""
        echo "📋 Creating dispatch rule..."
        
        # Check dispatch rule command syntax
        echo "🔍 Checking dispatch rule syntax:"
        livekit-cli sip dispatch create --help 2>&1 | head -15
        
        # Create dispatch rule JSON
        cat > /tmp/create_rule.json << EOF
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

        echo ""
        echo "📋 Dispatch rule configuration:"
        cat /tmp/create_rule.json
        
        # Create dispatch rule
        RULE_RESPONSE=$(livekit-cli sip dispatch create /tmp/create_rule.json 2>&1)
        
        echo "📋 Rule creation response:"
        echo "$RULE_RESPONSE"
        
        if echo "$RULE_RESPONSE" | grep -qi "rule.*created\|dispatchRuleId\|success"; then
            RULE_ID=$(echo "$RULE_RESPONSE" | grep -oE "[a-zA-Z0-9_-]{20,}" | head -1)
            if [ -z "$RULE_ID" ]; then
                RULE_ID=$(echo "$RULE_RESPONSE" | jq -r '.sipDispatchRuleId' 2>/dev/null || echo "RULE_ID_NOT_FOUND")
            fi
            
            echo "✅ Dispatch rule created successfully!"
            echo "🆔 Rule ID: $RULE_ID"
            
            echo ""
            echo "🎉 TWILIO SIP CONFIGURATION COMPLETE!"
            echo "====================================="
            echo "📞 Inbound number: +1 307 460 6119"
            echo "🏠 Target room: twilio-test-room"
            echo "🆔 Trunk ID: $TRUNK_ID"
            echo "📋 Rule ID: $RULE_ID"
            echo "📍 SIP URI: sip:+13074606119@${EXTERNAL_IP}:5170"
            echo ""
            echo "✅ Configure Twilio to send calls to this endpoint!"
            echo "🔧 Twilio SIP URI: sip:+13074606119@${EXTERNAL_IP}:5170"
            echo "====================================="
            exit 0
        else
            echo "❌ Dispatch rule creation failed"
            echo "Response: $RULE_RESPONSE"
        fi
    else
        echo "❌ Could not extract trunk ID from response"
        echo "Response: $TRUNK_RESPONSE"
    fi
else
    echo "❌ Trunk creation failed"
    echo "Response: $TRUNK_RESPONSE"
    
    # Try simpler approach without JSON file
    echo ""
    echo "🔄 Trying simple CLI flags approach..."
    SIMPLE_RESPONSE=$(livekit-cli sip inbound create --name "Twilio Inbound Trunk" --numbers "+13074606119" 2>&1)
    echo "📋 Simple command response:"
    echo "$SIMPLE_RESPONSE"
    
    if echo "$SIMPLE_RESPONSE" | grep -qi "trunk.*created\|success\|id"; then
        echo "✅ Simple command worked!"
        TRUNK_ID=$(echo "$SIMPLE_RESPONSE" | grep -oE "[a-zA-Z0-9_-]{20,}" | head -1)
        echo "🆔 Trunk ID: $TRUNK_ID"
    fi
fi

# Manual instructions if all automation fails
echo ""
echo "💡 MANUAL CREATION INSTRUCTIONS:"
echo "================================"
echo "If automated creation fails, use these details:"
echo "📞 Phone Number: +1 307 460 6119"
echo "🏠 Target Room: twilio-test-room"  
echo "📍 SIP Endpoint: sip:+13074606119@${EXTERNAL_IP}:5170"
echo "🔑 Metadata: provider=Twilio,number=+13074606119,type=inbound"
echo ""
echo "Create via LiveKit dashboard or use CLI commands manually."

echo "🏁 Twilio setup completed."