#!/bin/bash
set -e

echo "===========================================" 
echo "🔧 TWILIO SIP TRUNK SETUP STARTING"
echo "===========================================" 
echo "Setting up Twilio SIP Trunk and Dispatch Rule..."

# Set up LiveKit CLI environment (can be overridden at runtime)
export LIVEKIT_URL="${LIVEKIT_URL:-http://localhost:7880}"
export LIVEKIT_API_KEY="${LIVEKIT_API_KEY:-108378f337bbab3ce4e944554bed555a}"
export LIVEKIT_API_SECRET="${LIVEKIT_API_SECRET:-2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d}"

# Derive an API HTTP(S) URL from the LIVEKIT_URL (accept ws/wss inputs)
if [[ "$LIVEKIT_URL" == wss://* ]]; then
    API_URL="https://${LIVEKIT_URL#wss://}"
elif [[ "$LIVEKIT_URL" == ws://* ]]; then
    API_URL="http://${LIVEKIT_URL#ws://}"
elif [[ "$LIVEKIT_URL" == https://* || "$LIVEKIT_URL" == http://* ]]; then
    API_URL="$LIVEKIT_URL"
else
    API_URL="http://localhost:7880"
fi

echo "🔑 Using API Key: $LIVEKIT_API_KEY"
echo "🌐 LiveKit URL: $LIVEKIT_URL"
echo "🌐 LiveKit API URL: $API_URL"

# Wait for the LiveKit server (API) to be ready
echo "Waiting for LiveKit server to start (checking $API_URL/health)..."
timeout=60
while [ $timeout -gt 0 ]; do
    if curl -s -k "$API_URL/health" > /dev/null 2>&1; then
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

# (LIVEKIT_URL, LIVEKIT_API_KEY and LIVEKIT_API_SECRET are already configured above)
echo "📞 Creating Twilio inbound trunk and dispatch rule..."

# Create trunk using the working CLI flags
echo "📞 Creating trunk using working CLI flags..."
set +e
TRUNK_RESPONSE=$(livekit-cli --url "$API_URL" --api-key "$LIVEKIT_API_KEY" --api-secret "$LIVEKIT_API_SECRET" sip inbound create --name "Twilio Inbound Trunk" --numbers "+13074606119" 2>&1)
TRUNK_EXIT_CODE=$?
set -e

echo "📋 Trunk creation response (exit code: $TRUNK_EXIT_CODE):"
echo "$TRUNK_RESPONSE"

if [ $TRUNK_EXIT_CODE -eq 0 ]; then
    echo "✅ Trunk created successfully!"
    
    # Extract trunk ID properly
    TRUNK_ID=$(echo "$TRUNK_RESPONSE" | grep "SIPTrunkID:" | awk '{print $2}')
    if [ -z "$TRUNK_ID" ]; then
        # Alternative extraction
        TRUNK_ID=$(echo "$TRUNK_RESPONSE" | grep -oE "ST_[a-zA-Z0-9_-]+" | head -1)
    fi
    
    echo "🆔 Extracted Trunk ID: $TRUNK_ID"
    
    if [ ! -z "$TRUNK_ID" ]; then
        echo ""
        echo "📋 Creating dispatch rule with correct flags..."
        
        # Create dispatch rule using the correct CLI flags from help output
        set +e
    RULE_RESPONSE=$(livekit-cli --url "$API_URL" --api-key "$LIVEKIT_API_KEY" --api-secret "$LIVEKIT_API_SECRET" sip dispatch create --trunks "$TRUNK_ID" --direct "twilio-test-room" 2>&1)
        RULE_EXIT_CODE=$?
        set -e
        
        echo "📋 Rule creation response (exit code: $RULE_EXIT_CODE):"
        echo "$RULE_RESPONSE"
        
        if [ $RULE_EXIT_CODE -eq 0 ]; then
            RULE_ID=$(echo "$RULE_RESPONSE" | grep -oE "DR_[a-zA-Z0-9_-]+" | head -1)
            if [ -z "$RULE_ID" ]; then
                RULE_ID=$(echo "$RULE_RESPONSE" | grep "DispatchRuleID:" | awk '{print $2}')
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
            echo "📍 SIP URI: sip:${EXTERNAL_IP}:5060"
            echo ""
            echo "✅ READY FOR TWILIO CONFIGURATION!"
            echo "🔧 Configure Twilio SIP URI: sip:${EXTERNAL_IP}:5060"
            echo "====================================="
            
            # List final configuration
            echo ""
            echo "📋 Final trunk configuration:"
            livekit-cli --url "$API_URL" --api-key "$LIVEKIT_API_KEY" --api-secret "$LIVEKIT_API_SECRET" sip inbound list 2>&1 | grep -A 5 -B 5 "$TRUNK_ID" || echo "Could not display trunk details"
            
            echo ""
            echo "📋 Final dispatch rules:"
            livekit-cli --url "$API_URL" --api-key "$LIVEKIT_API_KEY" --api-secret "$LIVEKIT_API_SECRET" sip dispatch list 2>&1 | head -20 || echo "Could not list dispatch rules"
            
        else
            echo "❌ Dispatch rule creation failed with correct flags"
            echo "Error: $RULE_RESPONSE"
            
            # Try with name parameter as well
            echo ""
            echo "🔄 Trying with name parameter..."
            set +e
            ALT_RULE_RESPONSE=$(livekit-cli --url "$API_URL" --api-key "$LIVEKIT_API_KEY" --api-secret "$LIVEKIT_API_SECRET" sip dispatch create --name "Twilio Dispatch Rule" --trunks "$TRUNK_ID" --direct "twilio-test-room" 2>&1)
            ALT_EXIT_CODE=$?
            set -e
            
            echo "Alternative response (exit code: $ALT_EXIT_CODE):"
            echo "$ALT_RULE_RESPONSE"
            
            if [ $ALT_EXIT_CODE -eq 0 ]; then
                echo "✅ Alternative dispatch rule creation succeeded!"
                ALT_RULE_ID=$(echo "$ALT_RULE_RESPONSE" | grep -oE "DR_[a-zA-Z0-9_-]+" | head -1)
                echo "🆔 Rule ID: $ALT_RULE_ID"
            fi
        fi
    else
        echo "❌ Could not extract trunk ID"
    fi
else
    echo "❌ Trunk creation failed"
fi

# Summary - even if dispatch rule fails, trunk is created
echo ""
echo "🎯 CONFIGURATION SUMMARY:"
echo "========================"
echo "📞 Phone Number: +1 307 460 6119"
echo "🏠 Target Room: twilio-test-room"  
echo "📍 SIP Endpoint: sip:${EXTERNAL_IP}:5060"
if [ ! -z "$TRUNK_ID" ]; then
    echo "🆔 Trunk ID: $TRUNK_ID"
    echo "✅ Trunk Status: CREATED"
else
    echo "❌ Trunk Status: FAILED"
fi

if [ ! -z "$RULE_ID" ] || [ ! -z "$ALT_RULE_ID" ]; then
    echo "✅ Dispatch Rule Status: CREATED"
else
    echo "⚠️ Dispatch Rule Status: NEEDS MANUAL CREATION"
    echo "   Use: --trunks $TRUNK_ID --direct twilio-test-room"
fi

echo ""
echo "🔧 NEXT STEPS:"
echo "=============="
echo "1. Configure Twilio phone number +1 307 460 6119"
echo "2. Set SIP URI: sip:${EXTERNAL_IP}:5060"
echo "3. Test inbound calls to room: twilio-test-room"

echo "🏁 Twilio setup completed."