#!/bin/bash
# docker-entrypoint.sh - Fixed version

set -e

echo "=== Starting Voice Agent SIP Service ==="

# Start Redis in background if not running externally
if ! redis-cli -h 40.81.229.194 -p 6379 ping > /dev/null 2>&1; then
    echo "Starting Redis server..."
    redis-server --daemonize yes --bind 0.0.0.0 --port 6379
    sleep 2
fi

# Set environment variables for production
export EXTERNAL_IP="${EXTERNAL_IP:-40.81.229.194}"
export LIVEKIT_API_KEY="${LIVEKIT_API_KEY:-d6212ffd426f199fe1759c6370c85155}"
export LIVEKIT_API_SECRET="${LIVEKIT_API_SECRET:-6a7b312f5643020c86ceeef8785824e01f6ab1bd35394db1abf9d62e900ae23e}"
export SIP_USERNAME="${SIP_USERNAME:-00919240908080}"
export SIP_PASSWORD="${SIP_PASSWORD:-1234}"

echo "Configuration:"
echo "- External IP: $EXTERNAL_IP"
echo "- LiveKit URL: ws://$EXTERNAL_IP:7880"
echo "- Redis: $EXTERNAL_IP:6379"
echo "- SIP User: $SIP_USERNAME"

# Wait for LiveKit to be available
echo "Waiting for LiveKit server..."
until curl -f http://40.81.229.194:7880 > /dev/null 2>&1; do
    echo "LiveKit not ready yet, waiting..."
    sleep 5
done

echo "LiveKit server is ready!"

# Start the SIP service
echo "Starting SIP service..."
exec /app/sip-app --config /app/config.yaml