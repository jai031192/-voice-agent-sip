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

# First, let's test CLI connectivity
echo "🔍 Testing CLI connectivity..."
CLI_TEST=$(livekit-cli --help 2>&1 | head -5)
echo "CLI basic test: $CLI_TEST"

echo ""
echo "🔍 Testing SIP connectivity..."
SIP_TEST=$(livekit-cli sip --help 2>&1 | head -5)
echo "SIP test: $SIP_TEST"

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

# Test the CLI command with error handling that doesn't exit
echo ""
echo "🔄 Creating trunk with JSON file input..."
set +e  # Disable exit on error temporarily
TRUNK_RESPONSE=$(livekit-cli sip inbound create /tmp/create_trunk.json 2>&1)
TRUNK_EXIT_CODE=$?
set -e  # Re-enable exit on error

echo "📋 Trunk creation response (exit code: $TRUNK_EXIT_CODE):"
echo "$TRUNK_RESPONSE"

if [ $TRUNK_EXIT_CODE -eq 0 ]; then
    echo "✅ Trunk creation command executed successfully!"
    
    # Check if response contains success indicators
    if echo "$TRUNK_RESPONSE" | grep -qi "trunk.*created\|sipTrunkId\|success\|id"; then
        echo "✅ Trunk creation response looks successful!"
        
        # Extract trunk ID
        TRUNK_ID=$(echo "$TRUNK_RESPONSE" | grep -oE "[a-zA-Z0-9_-]{20,}" | head -1)
        if [ -z "$TRUNK_ID" ]; then
            TRUNK_ID=$(echo "$TRUNK_RESPONSE" | jq -r '.sipTrunkId' 2>/dev/null || echo "")
        fi
        
        if [ ! -z "$TRUNK_ID" ] && [ "$TRUNK_ID" != "null" ]; then
            echo "🆔 Extracted Trunk ID: $TRUNK_ID"
            
            echo ""
            echo "🎉 TWILIO SIP TRUNK CREATED SUCCESSFULLY!"
            echo "====================================="
            echo "📞 Inbound number: +1 307 460 6119"
            echo "🏠 Target room: twilio-test-room"
            echo "🆔 Trunk ID: $TRUNK_ID"
            echo "📍 SIP URI: sip:+13074606119@${EXTERNAL_IP}:5170"
            echo ""
            echo "✅ Configure Twilio to send calls to this endpoint!"
            echo "====================================="
        else
            echo "⚠️ Trunk may be created but ID extraction failed"
            echo "Full response: $TRUNK_RESPONSE"
        fi
    else
        echo "⚠️ Unexpected response format"
        echo "Full response: $TRUNK_RESPONSE"
    fi
else
    echo "❌ Trunk creation command failed with exit code: $TRUNK_EXIT_CODE"
    echo "Error response: $TRUNK_RESPONSE"
    
    # Try the simple approach
    echo ""
    echo "🔄 Trying simple CLI flags approach..."
    set +e
    SIMPLE_RESPONSE=$(livekit-cli sip inbound create --name "Twilio Inbound Trunk" --numbers "+13074606119" 2>&1)
    SIMPLE_EXIT_CODE=$?
    set -e
    
    echo "📋 Simple command response (exit code: $SIMPLE_EXIT_CODE):"
    echo "$SIMPLE_RESPONSE"
    
    if [ $SIMPLE_EXIT_CODE -eq 0 ]; then
        echo "✅ Simple command worked!"
        TRUNK_ID=$(echo "$SIMPLE_RESPONSE" | grep -oE "[a-zA-Z0-9_-]{20,}" | head -1)
        echo "🆔 Trunk ID: $TRUNK_ID"
    else
        echo "❌ Simple command also failed"
    fi
fi

# Manual instructions
echo ""
echo "💡 MANUAL CREATION INSTRUCTIONS:"
echo "================================"
echo "If automated creation fails, use these details:"
echo "📞 Phone Number: +1 307 460 6119"
echo "🏠 Target Room: twilio-test-room"  
echo "📍 SIP Endpoint: sip:+13074606119@${EXTERNAL_IP}:5170"
echo ""
echo "Create via LiveKit dashboard or CLI manually."

echo "🏁 Twilio setup completed."