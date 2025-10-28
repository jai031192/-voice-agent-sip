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

# Check available CLI commands
echo "🔍 Discovering inbound trunk creation commands..."
if command -v livekit-cli > /dev/null 2>&1; then
    echo "✅ LiveKit CLI found, investigating inbound commands..."
    
    # Show inbound trunk commands
    echo "📋 Checking inbound trunk management:"
    livekit-cli sip inbound --help 2>&1 | head -30
    
    echo ""
    echo "🔍 Looking for create/add commands:"
    livekit-cli sip inbound --help 2>&1 | grep -E "(create|add|new)" || echo "No create commands found in main help"
    
    # Try to find the exact command syntax
    echo ""
    echo "📞 Testing inbound trunk creation..."
    
    # Test Pattern 1: lk sip inbound create
    echo "🔄 Testing: livekit-cli sip inbound create"
    HELP_OUTPUT=$(livekit-cli sip inbound create --help 2>&1 || echo "COMMAND_NOT_FOUND")
    if echo "$HELP_OUTPUT" | grep -q "COMMAND_NOT_FOUND"; then
        echo "❌ 'create' subcommand not found"
    else
        echo "✅ Found 'create' subcommand!"
        echo "$HELP_OUTPUT" | head -20
        
        # Try to create the trunk
        echo ""
        echo "📞 Creating Twilio inbound trunk..."
        TRUNK_RESPONSE=$(livekit-cli sip inbound create \
            --name "Twilio Inbound Trunk" \
            --numbers "+13074606119" \
            --metadata "provider=Twilio,number=+13074606119,type=inbound" 2>&1 || echo "TRUNK_CREATION_FAILED")
        
        echo "📋 Trunk creation response:"
        echo "$TRUNK_RESPONSE"
        
        if echo "$TRUNK_RESPONSE" | grep -q "TRUNK_CREATION_FAILED"; then
            echo "❌ Trunk creation with basic flags failed"
        elif echo "$TRUNK_RESPONSE" | grep -qi "trunk.*created\|success\|id"; then
            echo "✅ Trunk creation succeeded!"
            TRUNK_ID=$(echo "$TRUNK_RESPONSE" | grep -oE "[a-zA-Z0-9_-]{20,}" | head -1)
            echo "🆔 Extracted Trunk ID: $TRUNK_ID"
            
            # Now create dispatch rule
            echo ""
            echo "📋 Creating dispatch rule..."
            
            # Check dispatch rule commands
            echo "🔍 Checking dispatch rule creation:"
            livekit-cli sip dispatch --help 2>&1 | head -20
            
            RULE_RESPONSE=$(livekit-cli sip dispatch create \
                --trunk-id "$TRUNK_ID" \
                --room "twilio-test-room" \
                --metadata "test=true,provider=Twilio" 2>&1 || echo "RULE_CREATION_FAILED")
            
            echo "📋 Rule creation response:"
            echo "$RULE_RESPONSE"
            
            if echo "$RULE_RESPONSE" | grep -qi "rule.*created\|success\|id"; then
                RULE_ID=$(echo "$RULE_RESPONSE" | grep -oE "[a-zA-Z0-9_-]{20,}" | head -1)
                echo "✅ Dispatch rule created successfully!"
                echo "🆔 Rule ID: $RULE_ID"
                
                echo ""
                echo "🎉 TWILIO SIP CONFIGURATION COMPLETE!"
                echo "====================================="
                echo "📞 Inbound number: +1 307 460 6119"
                echo "🏠 Target room: twilio-test-room"
                echo "🆔 Trunk ID: $TRUNK_ID"
                echo "📋 Rule ID: $RULE_ID"
                echo "📍 SIP URI: sip:+13074606119@${EXTERNAL_IP}:5060"
                echo ""
                echo "✅ Configure Twilio to send calls to this endpoint!"
                echo "====================================="
                exit 0
            else
                echo "❌ Dispatch rule creation failed"
                echo "Response: $RULE_RESPONSE"
            fi
        else
            echo "❌ Unexpected trunk creation response"
            echo "Response: $TRUNK_RESPONSE"
        fi
    fi
    
    # Test Pattern 2: lk sip inbound add
    echo ""
    echo "🔄 Testing: livekit-cli sip inbound add"
    HELP_OUTPUT=$(livekit-cli sip inbound add --help 2>&1 || echo "COMMAND_NOT_FOUND")
    if echo "$HELP_OUTPUT" | grep -q "COMMAND_NOT_FOUND"; then
        echo "❌ 'add' subcommand not found"
    else
        echo "✅ Found 'add' subcommand!"
        echo "$HELP_OUTPUT" | head -20
    fi
    
    # Test Pattern 3: List all available inbound commands
    echo ""
    echo "📋 All available inbound commands:"
    livekit-cli sip inbound --help 2>&1 | grep -E "^\s*[a-z]" || echo "No subcommands found"
    
    # Manual instructions if automated creation fails
    echo ""
    echo "💡 MANUAL CREATION INSTRUCTIONS:"
    echo "================================"
    echo "If automated creation fails, use these details:"
    echo "📞 Phone Number: +1 307 460 6119"
    echo "🏠 Target Room: twilio-test-room"  
    echo "📍 SIP Endpoint: sip:+13074606119@${EXTERNAL_IP}:5060"
    echo "🔑 Metadata: provider=Twilio,number=+13074606119,type=inbound"
    echo ""
    echo "Use the LiveKit dashboard or correct CLI syntax to create manually."
    
else
    echo "❌ LiveKit CLI not found"
    exit 1
fi

echo "🏁 Twilio setup completed."