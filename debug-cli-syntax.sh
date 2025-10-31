#!/bin/bash

echo "🔍 DEBUG: Testing LiveKit CLI Syntax"
echo "====================================="

# Set environment variables
export LIVEKIT_URL="http://localhost:7880"
export LIVEKIT_API_KEY="108378f337bbab3ce4e944554bed555a"
export LIVEKIT_API_SECRET="2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d"
export PHONE_NUMBER="+13074606119"

echo "🔍 Step 1: Check CLI version and available commands"
echo "=================================================="
lk --version
echo ""
echo "Available SIP commands:"
lk sip --help
echo ""

echo "🔍 Step 2: List existing SIP trunks"
echo "==================================="
lk sip list-trunk \
    --url "${LIVEKIT_URL}" \
    --api-key "${LIVEKIT_API_KEY}" \
    --api-secret "${LIVEKIT_API_SECRET}" || echo "❌ List trunk failed"
echo ""

echo "🔍 Step 3: Test trunk creation syntax options"
echo "============================================="

# Option 1: Try with direct parameters
echo "Trying Option 1: Direct parameters"
lk sip create-inbound-trunk \
    --url "${LIVEKIT_URL}" \
    --api-key "${LIVEKIT_API_KEY}" \
    --api-secret "${LIVEKIT_API_SECRET}" \
    --trunk-id "test-trunk-1" \
    --name "Test Trunk" \
    --numbers "${PHONE_NUMBER}" 2>&1 | head -10

echo ""

# Option 2: Try with JSON file
echo "Trying Option 2: JSON file approach"
cat > /tmp/test-trunk.json << EOF
{
  "name": "Test Trunk JSON",
  "numbers": ["${PHONE_NUMBER}"],
  "metadata": "provider=Twilio,number=${PHONE_NUMBER},type=inbound"
}
EOF

echo "JSON content:"
cat /tmp/test-trunk.json
echo ""

lk sip create-inbound-trunk \
    --url "${LIVEKIT_URL}" \
    --api-key "${LIVEKIT_API_KEY}" \
    --api-secret "${LIVEKIT_API_SECRET}" \
    --request /tmp/test-trunk.json 2>&1 | head -10

echo ""

# Option 3: Check help for exact syntax
echo "🔍 Step 4: Get exact create-inbound-trunk syntax"
echo "==============================================="
lk sip create-inbound-trunk --help || echo "❌ Help command failed"

echo ""

echo "🔍 Step 5: Test different CLI binary names"
echo "=========================================="
echo "Testing 'livekit-cli':"
livekit-cli --version 2>&1 | head -3

echo "Testing 'lk':"
lk --version 2>&1 | head -3

echo ""
echo "🔍 DEBUG COMPLETE"
echo "=================="
echo "Run this script inside your container to debug the CLI syntax!"