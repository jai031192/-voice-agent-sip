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
echo "🔍 Checking LiveKit CLI SIP commands..."
if command -v livekit-cli > /dev/null 2>&1; then
    echo "✅ LiveKit CLI found, checking SIP subcommands..."
    
    # Show SIP subcommands
    echo "📋 Available SIP commands:"
    livekit-cli sip --help | head -20
    
    echo ""
    echo "🔍 Looking for trunk creation commands:"
    livekit-cli sip --help | grep -i trunk || echo "No trunk commands found"
    
    echo ""
    echo "🔍 Full SIP help output:"
    livekit-cli sip --help
    
    echo ""
    echo "📞 Attempting to create Twilio inbound trunk using CLI..."
    
    # Try the CLI approach with proper SIP commands
    echo "🔄 Testing CLI trunk creation commands..."
    
    # Check if create-trunk command exists
    if livekit-cli sip --help | grep -q "create-trunk"; then
        echo "✅ Found 'create-trunk' command, attempting to use it..."
        
        # Create trunk JSON file
        cat > /tmp/trunk.json << EOF
{
  "name": "Twilio Inbound Trunk",
  "inbound_numbers": ["+13074606119"],
  "metadata": "provider=Twilio,number=+13074606119,type=inbound"
}
EOF

        echo "📋 Trunk configuration:"
        cat /tmp/trunk.json
        
        # Try to create trunk
        TRUNK_RESPONSE=$(livekit-cli sip create-trunk --trunk-config /tmp/trunk.json 2>&1 || echo "CLI_TRUNK_FAILED")
        echo "📋 Trunk creation response:"
        echo "$TRUNK_RESPONSE"
        
        if echo "$TRUNK_RESPONSE" | grep -q "CLI_TRUNK_FAILED"; then
            echo "❌ CLI trunk creation failed, trying alternative formats..."
            
            # Try with different flag names
            TRUNK_RESPONSE=$(livekit-cli sip create-trunk --config /tmp/trunk.json 2>&1 || echo "CLI_TRUNK_FAILED_2")
            echo "📋 Alternative trunk creation response:"
            echo "$TRUNK_RESPONSE"
        fi
        
    elif livekit-cli sip --help | grep -q "trunk"; then
        echo "✅ Found trunk-related commands, checking available options..."
        livekit-cli sip --help | grep trunk
        
        # Try generic trunk command
        TRUNK_RESPONSE=$(livekit-cli sip trunk create --help 2>&1 || echo "NO_TRUNK_CREATE")
        echo "📋 Trunk create help:"
        echo "$TRUNK_RESPONSE"
        
    else
        echo "❌ No trunk creation commands found in SIP help"
        echo "📋 Full available commands:"
        livekit-cli sip --help
        
        # Let's try some common variations
        echo ""
        echo "🔄 Trying common CLI patterns..."
        
        # Pattern 1: Direct parameters
        echo "Testing: livekit-cli sip create-inbound-trunk"
        livekit-cli sip create-inbound-trunk --help 2>&1 | head -10 || echo "Command not found"
        
        # Pattern 2: Alternative naming
        echo "Testing: livekit-cli create-sip-trunk"
        livekit-cli create-sip-trunk --help 2>&1 | head -10 || echo "Command not found"
        
        # Pattern 3: Using lk instead
        if command -v lk > /dev/null 2>&1; then
            echo "Testing: lk sip create-trunk"
            lk sip create-trunk --help 2>&1 | head -10 || echo "lk command not found"
        fi
    fi
    
    echo ""
    echo "🎯 SUMMARY: Manual trunk creation required"
    echo "ℹ️  Based on the CLI investigation, you'll need to create:"
    echo "   📞 Inbound trunk for: +13074606119"
    echo "   🏠 Dispatch rule to room: twilio-test-room"
    echo "   📍 SIP endpoint: sip:+13074606119@${EXTERNAL_IP}:5170"
    echo ""
    echo "💡 Use the LiveKit dashboard or proper CLI syntax once identified"
    
else
    echo "❌ LiveKit CLI not found"
    exit 1
fi

echo "🏁 Twilio setup investigation completed."