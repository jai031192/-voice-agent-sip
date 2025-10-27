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

echo "📞 Creating Twilio inbound trunk using working CLI approach..."

# First, list existing trunks to see the format
echo "🔍 Listing existing trunks to understand format..."
set +e
EXISTING_TRUNKS=$(livekit-cli sip inbound list 2>&1)
LIST_EXIT_CODE=$?
set -e

echo "📋 Existing trunks (exit code: $LIST_EXIT_CODE):"
echo "$EXISTING_TRUNKS"

# Create trunk using the working simple approach
echo ""
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
        echo "📋 Now creating dispatch rule..."
        
        # Check dispatch rule commands
        echo "🔍 Checking dispatch rule syntax:"
        set +e
        DISPATCH_HELP=$(livekit-cli sip dispatch create --help 2>&1)
        HELP_EXIT_CODE=$?
        set -e
        
        echo "Dispatch help (exit code: $HELP_EXIT_CODE):"
        echo "$DISPATCH_HELP"
        
        # Create dispatch rule using CLI flags
        echo ""
        echo "📋 Creating dispatch rule with CLI flags..."
        set +e
        RULE_RESPONSE=$(livekit-cli sip dispatch create --trunk-ids "$TRUNK_ID" --room "twilio-test-room" 2>&1)
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
            echo "✅ Configure Twilio to send calls to this endpoint!"
            echo "🔧 Twilio SIP URI: sip:+13074606119@${EXTERNAL_IP}:5170"
            echo "====================================="
            
            # List final configuration
            echo ""
            echo "📋 Final trunk list:"
            livekit-cli sip inbound list 2>&1 | head -20 || echo "Could not list trunks"
            
            echo ""
            echo "📋 Final dispatch rules:"
            livekit-cli sip dispatch list 2>&1 | head -20 || echo "Could not list rules"
            
        else
            echo "❌ Dispatch rule creation failed"
            echo "Error: $RULE_RESPONSE"
            
            # Try alternative dispatch rule syntax
            echo ""
            echo "🔄 Trying alternative dispatch rule syntax..."
            set +e
            ALT_RULE_RESPONSE=$(livekit-cli sip dispatch create --trunk-id "$TRUNK_ID" --room-name "twilio-test-room" 2>&1)
            ALT_EXIT_CODE=$?
            set -e
            
            echo "Alternative response (exit code: $ALT_EXIT_CODE):"
            echo "$ALT_RULE_RESPONSE"
        fi
    else
        echo "❌ Could not extract trunk ID"
    fi
else
    echo "❌ Trunk creation failed"
fi

# Manual instructions
echo ""
echo "💡 SUMMARY:"
echo "==========="
echo "📞 Phone Number: +1 307 460 6119"
echo "🏠 Target Room: twilio-test-room"  
echo "📍 SIP Endpoint: sip:+13074606119@${EXTERNAL_IP}:5170"
echo "🆔 Trunk ID: $TRUNK_ID"
echo ""
echo "Configure Twilio to route calls to this SIP endpoint!"

echo "🏁 Twilio setup completed."