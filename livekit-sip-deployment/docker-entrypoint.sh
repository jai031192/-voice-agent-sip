#!/bin/bash

echo "🚀 Starting LiveKit SIP Service Stack for MONKHUB..."

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
./livekit-server --config livekit-config.yaml &
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
export LIVEKIT_URL="http://localhost:7880"
export LIVEKIT_API_KEY="API5DcPxqyBDHLr"
export LIVEKIT_API_SECRET="b9dgi6VEHsXf1zLKFWffHONECta5Xvfs5ejgdZhUoxPE"

# Create SIP trunk and dispatch rule for MONKHUB
echo "📞 Setting up MONKHUB SIP configuration..."
cat > /tmp/sip-trunk.json << 'EOF'
{
  "trunk": {
    "name": "monkhub-trunk",
    "metadata": "provider=MONKHUB_INNOVATIONS,customer_ip=40.81.229.194,sbc_ip=27.107.220.6,tsi=INT-MU-SBC06-9345",
    "numbers": ["9240908080"],
    "auth_username": "00919240908080",
    "auth_password": "1234"
  }
}
EOF

cat > /tmp/dispatch-rule.json << 'EOF'
{
  "name": "monkhub-dispatch",
  "metadata": "provider=MONKHUB_INNOVATIONS,del_number=9240908080,target_room=monkhub-sip-room",
  "rule": {
    "dispatch_rule_direct": {
      "room_name": "monkhub-sip-room",
      "pin": ""
    }
  },
  "trunk_ids": ["PLACEHOLDER_TRUNK_ID"]
}
EOF

# Function to setup SIP configuration
setup_sip_config() {
    echo "🔧 Creating SIP trunk for MONKHUB..."
    TRUNK_RESPONSE=$(./livekit-cli sip inbound create /tmp/sip-trunk.json 2>/dev/null)
    if [ $? -eq 0 ]; then
        TRUNK_ID=$(echo "$TRUNK_RESPONSE" | grep -o 'SIPTrunkID: ST_[a-zA-Z0-9]*' | cut -d' ' -f2)
        if [ -n "$TRUNK_ID" ]; then
            echo "✅ SIP Trunk created: $TRUNK_ID"
            
            # Update dispatch rule with actual trunk ID
            sed -i "s/PLACEHOLDER_TRUNK_ID/$TRUNK_ID/g" /tmp/dispatch-rule.json
            
            echo "🎯 Creating dispatch rule..."
            DISPATCH_RESPONSE=$(./livekit-cli sip dispatch create /tmp/dispatch-rule.json 2>/dev/null)
            if [ $? -eq 0 ]; then
                echo "✅ Dispatch rule created successfully"
                echo "📞 MONKHUB calls to 9240908080 will route to 'monkhub-sip-room'"
            else
                echo "⚠️  Dispatch rule creation failed, but continuing..."
            fi
        fi
    else
        echo "⚠️  SIP trunk creation failed, but continuing..."
    fi
}

# Try to setup SIP config (retry logic)
for i in $(seq 1 3); do
    setup_sip_config && break
    echo "🔄 Retrying SIP setup in 5 seconds... (attempt $i/3)"
    sleep 5
done

# Start SIP service (foreground)
echo "📞 Starting SIP Service..."
echo "🌐 MONKHUB SIP Service ready:"
echo "   - SIP Endpoint: 0.0.0.0:5170"
echo "   - LiveKit API: 0.0.0.0:7880" 
echo "   - Health Check: 0.0.0.0:8080"
echo "   - Provider: MONKHUB (27.107.220.6)"
echo "   - Phone: +919240908080 → monkhub-sip-room"
echo "   - Customer IP: 40.81.229.194"

exec ./sip --config config.yaml