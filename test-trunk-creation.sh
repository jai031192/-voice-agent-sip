#!/bin/bash

echo "🧪 SIMPLE SIP TRUNK CREATION TEST"
echo "================================="

# Test the current working setup first
echo "📞 Testing simple trunk creation..."

# Create simple trunk JSON
cat > /tmp/simple-trunk.json << 'EOF'
{
  "name": "Simple Test Trunk",
  "numbers": ["+13074606119"],
  "metadata": "test=true"
}
EOF

echo "📋 Using JSON:"
cat /tmp/simple-trunk.json
echo ""

# Try the old CLI first
echo "🔍 Testing old CLI (livekit-cli)..."
livekit-cli sip inbound create /tmp/simple-trunk.json \
    --url "http://localhost:7880" \
    --api-key "108378f337bbab3ce4e944554bed555a" \
    --api-secret "2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d" \
    --output json 2>&1

echo ""

# Try the new CLI
echo "🔍 Testing new CLI (lk)..."
lk sip create-inbound-trunk \
    --url "http://localhost:7880" \
    --api-key "108378f337bbab3ce4e944554bed555a" \
    --api-secret "2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d" \
    --request /tmp/simple-trunk.json 2>&1

echo ""
echo "✅ Test complete! Check output above to see which syntax works."