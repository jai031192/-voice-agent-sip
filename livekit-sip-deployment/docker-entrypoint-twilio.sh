#!/bin/bash

echo "🚀 Starting LiveKit SIP Service Stack for Twilio..."

# Start Redis in background
echo "📊 Starting Redis..."
redis-server --daemonize yes --port 6379 --bind 0.0.0.0
sleep 3

# Verify Redis is running
redis-cli ping
if [ $? -ne 0 ]; then
    echo "❌ Redis failed to start"
    exit 1
fi

# Start LiveKit server in background
echo "🎥 Starting LiveKit Server..."
/usr/local/bin/livekit-server --config livekit-config.yaml &
LIVEKIT_PID=$!
sleep 10

# Wait for LiveKit to be ready
echo "⏳ Waiting for LiveKit Server to be ready..."
for i in $(seq 1 30); do
    if wget --spider -q http://localhost:7880; then
        echo "✅ LiveKit Server is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ LiveKit Server failed to start"
        exit 1
    fi
    sleep 2
done

# Set environment variables for SIP service
export LIVEKIT_URL="${LIVEKIT_URL:-http://localhost:7880}"
export LIVEKIT_API_KEY="${LIVEKIT_API_KEY:-108378f337bbab3ce4e944554bed555a}"
export LIVEKIT_API_SECRET="${LIVEKIT_API_SECRET:-2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d}"
export EXTERNAL_IP="${EXTERNAL_IP:-40.81.229.194}"
export PHONE_NUMBER="${PHONE_NUMBER:-+13074606119}"

# Setup Twilio SIP configuration
echo "📞 Setting up Twilio SIP configuration..."

# Create trunk using JSON file format for Twilio
echo "📞 Creating Twilio inbound trunk..."

# Create trunk JSON file for Twilio
cat > /tmp/trunk.json << EOF
{
  "trunk": {
    "name": "Twilio Inbound SIP Trunk",
    "numbers": [
      "${PHONE_NUMBER}"
    ],
    "krispEnabled": true
  }
}
EOF

echo "📋 Trunk JSON content:"
cat /tmp/trunk.json

TRUNK_RESULT=$(/usr/local/bin/lk sip inbound create \
    --url "${LIVEKIT_URL}" \
    --api-key "${LIVEKIT_API_KEY}" \
    --api-secret "${LIVEKIT_API_SECRET}" \
    /tmp/trunk.json 2>&1)
echo "⚠️  Skipping automatic trunk/dispatch setup due to CLI version changes"
echo "ℹ️  The SIP service is running and ready to receive calls"
echo "ℹ️  You can manually configure trunks and dispatch rules via LiveKit dashboard"

TRUNK_STATUS="MANUAL"
DISPATCH_STATUS="MANUAL"

# # Delete any existing conflicting trunks for this number
# echo "🗑️ Cleaning up any existing trunks for number ${PHONE_NUMBER}..."
# EXISTING_TRUNKS=$(/usr/local/bin/lk sip list-trunk \
#     --url "${LIVEKIT_URL}" \
#     --api-key "${LIVEKIT_API_KEY}" \
#     --api-secret "${LIVEKIT_API_SECRET}" \
#     --project "$(echo ${LIVEKIT_API_KEY} | cut -d: -f1)" 2>/dev/null || echo "[]")

# if [ "$EXISTING_TRUNKS" != "[]" ] && [ -n "$EXISTING_TRUNKS" ]; then
#     echo "$EXISTING_TRUNKS" | jq -r '.[] | select(.numbers[] == "'"$PHONE_NUMBER"'") | .sip_trunk_id' | while read -r trunk_id; do
#         if [ -n "$trunk_id" ] && [ "$trunk_id" != "null" ]; then
#             echo "🗑️ Deleting existing trunk: $trunk_id"
#             /usr/local/bin/lk sip delete-trunk "$trunk_id" \
#                 --url "${LIVEKIT_URL}" \
#                 --api-key "${LIVEKIT_API_KEY}" \
#                 --api-secret "${LIVEKIT_API_SECRET}" \
#                 --project "$(echo ${LIVEKIT_API_KEY} | cut -d: -f1)" || echo "⚠️ Failed to delete trunk $trunk_id"
#         fi
#     done
# fi

# # Create trunk JSON (commented out due to CLI version changes)
# cat > /tmp/trunk.json << EOF
# {
#   "name": "Twilio Inbound Trunk", 
#   "numbers": ["${PHONE_NUMBER}"],
#   "metadata": "provider=Twilio,number=${PHONE_NUMBER},type=inbound"
# }
# EOF

# echo "📋 Trunk JSON content:"
# cat /tmp/trunk.json

# # Create trunk  
# echo "📞 Creating trunk..."
# TRUNK_RESULT=$(/usr/local/bin/lk sip create-inbound-trunk \
#     --url "${LIVEKIT_URL}" \
#     --api-key "${LIVEKIT_API_KEY}" \
#     --api-secret "${LIVEKIT_API_SECRET}" \
#     --project "$(echo ${LIVEKIT_API_KEY} | cut -d: -f1)" \
#     --request /tmp/trunk.json 2>&1)

TRUNK_EXIT_CODE=$?
echo "📋 Trunk creation result (exit code: $TRUNK_EXIT_CODE):"
echo "$TRUNK_RESULT"

# Process trunk creation result
if [ $TRUNK_EXIT_CODE -eq 0 ]; then
    TRUNK_ID=$(echo "$TRUNK_RESULT" | jq -r '.sip_trunk_id // .trunkId // .id' 2>/dev/null)
    if [ "$TRUNK_ID" != "null" ] && [ -n "$TRUNK_ID" ]; then
        echo "✅ Trunk created successfully with ID: $TRUNK_ID"
        TRUNK_STATUS="SUCCESS"
        
        # Create dispatch rule with trunk ID using JSON format
        echo "📞 Creating dispatch rule for individual rooms..."
        
        # Create dispatch rule JSON file for Twilio (matches all trunks by default)
        cat > /tmp/dispatch.json << EOF
{
  "dispatch_rule": {
    "rule": {
      "dispatchRuleIndividual": {
        "roomPrefix": "call-"
      }
    },
    "name": "Twilio Individual Room Dispatch",
    "roomConfig": {
      "agents": [{
        "agentName": "voice-agent",
        "metadata": "Twilio inbound call handler"
      }]
    }
  }
}
EOF

        echo "📋 Dispatch rule JSON content:"
        cat /tmp/dispatch.json

        DISPATCH_RESULT=$(/usr/local/bin/lk sip dispatch create \
            --url "${LIVEKIT_URL}" \
            --api-key "${LIVEKIT_API_KEY}" \
            --api-secret "${LIVEKIT_API_SECRET}" \
            /tmp/dispatch.json 2>&1)
        
        DISPATCH_EXIT_CODE=$?
        echo "📋 Dispatch rule creation result (exit code: $DISPATCH_EXIT_CODE):"
        echo "$DISPATCH_RESULT"

        if [ $DISPATCH_EXIT_CODE -eq 0 ]; then
            DISPATCH_ID=$(echo "$DISPATCH_RESULT" | jq -r '.sip_dispatch_rule_id // .dispatchRuleId // .id' 2>/dev/null)
            echo "✅ Dispatch rule created successfully with ID: $DISPATCH_ID"
            
            TRUNK_STATUS="SUCCESS"
            DISPATCH_STATUS="SUCCESS"
        else
            echo "❌ Dispatch rule creation failed"
            TRUNK_STATUS="SUCCESS"
            DISPATCH_STATUS="FAILED"
        fi
    else
        echo "❌ Failed to extract trunk ID from result"
        TRUNK_STATUS="FAILED"
        DISPATCH_STATUS="SKIPPED"
    fi
else
    echo "❌ Trunk creation failed"
    TRUNK_STATUS="FAILED"
    DISPATCH_STATUS="SKIPPED"
fi

# Configuration summary
echo ""
echo "🎯 CONFIGURATION SUMMARY:"
echo "=========================="
echo "📞 Phone Number: ${PHONE_NUMBER}"
echo "🏠 Room Prefix: call-"
echo "📍 SIP Endpoint: sip:${EXTERNAL_IP}:5060"
echo "✅ Trunk Status: ${TRUNK_STATUS}"
echo "✅ Dispatch Rule Status: ${DISPATCH_STATUS}"

if [ "$TRUNK_STATUS" = "SUCCESS" ] && [ "$DISPATCH_STATUS" = "SUCCESS" ]; then
    echo ""
    echo "🎉 TWILIO SIP CONFIGURATION COMPLETE!"
    echo ""
    echo "🔧 INDIVIDUAL ROOM SETUP:"
    echo "========================"
    echo "📞 Each call will create: call-<unique-id>"
    echo "🤖 Agent will auto-join each new room"
    echo "📍 SIP URI for Twilio: sip:${EXTERNAL_IP}:5060"
    echo ""
    echo "🔧 NEXT STEPS:"
    echo "=============="
    echo "1. Configure Twilio phone number ${PHONE_NUMBER}"
    echo "2. Set SIP URI: sip:${EXTERNAL_IP}:5060"
    echo "3. Test inbound calls - each will create room: call-<unique-id>"
    echo "4. Agent will auto-join each new call room"
else
    echo ""
    echo "⚠️  Manual configuration required via LiveKit dashboard"
    echo "    or use CLI commands to create trunk and dispatch rules"
fi

# Start SIP service (foreground)
echo "📞 Starting SIP Service..."
echo "🌐 Twilio SIP Service ready:"
echo "   - SIP Endpoint: 0.0.0.0:5060"
echo "   - LiveKit API: 0.0.0.0:7880" 
echo "   - Health Check: 0.0.0.0:8080"
echo "   - Provider: Twilio"
echo "   - Phone: ${PHONE_NUMBER} → call-<unique-id>"
echo "   - External IP: ${EXTERNAL_IP}"

exec /app/sip-app --config config.yaml