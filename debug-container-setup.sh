#!/bin/bash

set -e

echo "🧪 CONTAINER DEBUG: TWILIO SIP TRUNK SETUP"
echo "==========================================="
echo "Testing trunk creation inside container..."

# Environment variables for container
LIVEKIT_API_KEY="${LIVEKIT_API_KEY:-108378f337bbab3ce4e944554bed555a}"
LIVEKIT_API_SECRET="${LIVEKIT_API_SECRET:-2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d}"
LIVEKIT_URL="${LIVEKIT_URL:-http://localhost:7880}"  # Container uses HTTP
EXTERNAL_IP="${EXTERNAL_IP:-40.81.229.194}"
SIP_PORT="${SIP_PORT:-5060}"
PHONE_NUMBER="${PHONE_NUMBER:-+13074606119}"

echo "🔑 Using API Key: ${LIVEKIT_API_KEY}"
echo "🌐 LiveKit URL: ${LIVEKIT_URL}"

# Wait for LiveKit server
echo "⏳ Waiting for LiveKit server..."
for i in {1..10}; do
    if curl -s "${LIVEKIT_URL}/health" > /dev/null 2>&1; then
        echo "✅ LiveKit server is ready!"
        break
    fi
    echo "⏳ Waiting for LiveKit server... ($i/10)"
    sleep 2
done

# Test both CLI approaches
echo ""
echo "🔍 TESTING CLI APPROACHES"
echo "========================="

echo "📍 Step 1: Check available CLI binaries"
echo "Which livekit-cli: $(which livekit-cli 2>/dev/null || echo 'not found')"
echo "Which lk: $(which lk 2>/dev/null || echo 'not found')"
echo ""

# Create trunk JSON (your working format)
cat > /tmp/debug-trunk.json << EOF
{
  "name": "Debug Twilio Trunk",
  "numbers": ["${PHONE_NUMBER}"],
  "metadata": "provider=Twilio,number=${PHONE_NUMBER},type=debug"
}
EOF

echo "📋 Using trunk JSON:"
cat /tmp/debug-trunk.json
echo ""

# Test Method 1: Original working command
echo "📍 Step 2: Testing original livekit-cli command"
echo "=============================================="
if command -v livekit-cli > /dev/null; then
    echo "✅ livekit-cli found, testing..."
    livekit-cli sip inbound create /tmp/debug-trunk.json \
        --url "${LIVEKIT_URL}" \
        --api-key "${LIVEKIT_API_KEY}" \
        --api-secret "${LIVEKIT_API_SECRET}" \
        --output json 2>&1 || echo "❌ Original command failed"
else
    echo "❌ livekit-cli not found"
fi
echo ""

# Test Method 2: New lk command
echo "📍 Step 3: Testing new lk command"
echo "================================="
if command -v lk > /dev/null; then
    echo "✅ lk found, testing..."
    
    # Try different variations
    echo "Variation 1: With --request flag"
    lk sip create-inbound-trunk \
        --url "${LIVEKIT_URL}" \
        --api-key "${LIVEKIT_API_KEY}" \
        --api-secret "${LIVEKIT_API_SECRET}" \
        --request /tmp/debug-trunk.json 2>&1 || echo "❌ Variation 1 failed"
    
    echo ""
    echo "Variation 2: Direct parameters"
    lk sip create-inbound-trunk \
        --url "${LIVEKIT_URL}" \
        --api-key "${LIVEKIT_API_KEY}" \
        --api-secret "${LIVEKIT_API_SECRET}" \
        --name "Debug Direct Trunk" \
        --numbers "${PHONE_NUMBER}" 2>&1 || echo "❌ Variation 2 failed"
    
    echo ""
    echo "Variation 3: Check help for correct syntax"
    lk sip create-inbound-trunk --help 2>&1 | head -20
    
else
    echo "❌ lk not found"
fi

echo ""
echo "📍 Step 4: List existing trunks (if any created)"
echo "==============================================="
if command -v lk > /dev/null; then
    lk sip list-trunk \
        --url "${LIVEKIT_URL}" \
        --api-key "${LIVEKIT_API_KEY}" \
        --api-secret "${LIVEKIT_API_SECRET}" 2>&1 || echo "❌ List failed"
elif command -v livekit-cli > /dev/null; then
    livekit-cli sip list-trunk \
        --url "${LIVEKIT_URL}" \
        --api-key "${LIVEKIT_API_KEY}" \
        --api-secret "${LIVEKIT_API_SECRET}" \
        --output json 2>&1 || echo "❌ List failed"
fi

echo ""
echo "🎯 DEBUG SUMMARY"
echo "================"
echo "📞 Phone Number: ${PHONE_NUMBER}"
echo "🌐 LiveKit URL: ${LIVEKIT_URL}"
echo "📍 External IP: ${EXTERNAL_IP}"
echo ""
echo "✅ Debug script complete!"
echo "   Copy output above to identify working CLI syntax"