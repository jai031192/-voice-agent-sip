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

echo "📞 Creating Twilio inbound trunk and dispatch rule..."

# Create trunk using the working CLI flags
echo "📞 Creating trunk using working CLI flags..."
set +e
TRUNK_RESPONSE=$(livekit-cli sip inbound create --name "Twilio Inbound Trunk" --numbers "+13074606119" 2>&1)
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
        RULE_RESPONSE=$(livekit-cli sip dispatch create --trunks "$TRUNK_ID" --direct "twilio-test-room" 2>&1)
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
            echo "📍 SIP URI: sip:+13074606119@${EXTERNAL_IP}:5170"
            echo ""
            echo "✅ READY FOR TWILIO CONFIGURATION!"
            echo "🔧 Configure Twilio SIP URI: sip:+13074606119@${EXTERNAL_IP}:5170"
            echo "====================================="
            
            # List final configuration
            echo ""
            echo "📋 Final trunk configuration:"
            livekit-cli sip inbound list 2>&1 | grep -A 5 -B 5 "$TRUNK_ID" || echo "Could not display trunk details"
            
            echo ""
            echo "📋 Final dispatch rules:"
            livekit-cli sip dispatch list 2>&1 | head -20 || echo "Could not list dispatch rules"
            
        else
            echo "❌ Dispatch rule creation failed with correct flags"
            echo "Error: $RULE_RESPONSE"
            
            # Try with name parameter as well
            echo ""
            echo "🔄 Trying with name parameter..."
            set +e
            ALT_RULE_RESPONSE=$(livekit-cli sip dispatch create --name "Twilio Dispatch Rule" --trunks "$TRUNK_ID" --direct "twilio-test-room" 2>&1)
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
echo "📍 SIP Endpoint: sip:+13074606119@${EXTERNAL_IP}:5170"
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
echo "2. Set SIP URI: sip:+13074606119@${EXTERNAL_IP}:5170"
echo "3. Test inbound calls to room: twilio-test-room"

echo "🏁 Twilio setup completed."