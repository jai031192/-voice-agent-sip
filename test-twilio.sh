#!/bin/bash

echo "🧪 Twilio SIP Integration Test Script"
echo "======================================"
echo ""

# Check if container is running
if ! docker ps | grep -q "voice-agent-sip-container"; then
    echo "❌ Container is not running. Please start it first:"
    echo "docker run -d --name voice-agent-sip-container -p 5170:5170 -p 8080:8080 voice-agent-sip:latest"
    exit 1
fi

echo "✅ Container is running"
echo ""

# Check service health
echo "🔍 Checking service health..."
if curl -s http://localhost:8080/health > /dev/null; then
    echo "✅ Health endpoint responding"
else
    echo "❌ Health endpoint not responding"
fi

echo ""
echo "📋 Container logs (last 20 lines):"
echo "=================================="
docker logs voice-agent-sip-container | tail -20

echo ""
echo "🔧 Twilio Setup Logs:"
echo "===================="
docker exec voice-agent-sip-container cat /var/log/twilio-setup.log 2>/dev/null || echo "Setup log not available yet"

echo ""
echo "📞 Twilio Configuration:"
echo "======================="
echo "Inbound Number: +1 307 460 6119"
echo "Target Room: twilio-test-room" 
echo "SIP URI: sip:+13074606119@40.81.229.194:5170"
echo ""
echo "🔗 Next Steps:"
echo "1. Configure Twilio SIP Trunk to point to: sip:+13074606119@40.81.229.194:5170"
echo "2. Make a test call to +1 307 460 6119"
echo "3. Check LiveKit room 'twilio-test-room' for the incoming participant"
echo ""
echo "📚 Twilio SIP Configuration Guide:"
echo "https://www.twilio.com/docs/sip-trunking/terminating-sip-trunk"