#!/bin/bash

# Quick Fix Commands for VM - Run these on 40.81.229.194

echo "=== Voice Agent SIP Docker Fix Script ==="

# 1. First, check what's currently running
echo "1. Checking current containers..."
docker ps

# Check for specific container name first
CONTAINER_NAME="livekit-sip-monkhub"

if docker ps --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
    echo "Found container: $CONTAINER_NAME"
    echo "Checking logs..."
    docker logs $CONTAINER_NAME --tail 50
    
    # 2. Stop current container
    echo "2. Stopping current container..."
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
else
    echo "Container $CONTAINER_NAME not found, checking for other SIP containers..."
    # Fallback to search for any SIP/LiveKit containers
    OTHER_CONTAINER=$(docker ps --format "{{.Names}}" | grep -E "(sip|livekit)" | head -1)
    if [ ! -z "$OTHER_CONTAINER" ]; then
        echo "Found other container: $OTHER_CONTAINER"
        docker logs $OTHER_CONTAINER --tail 50
        docker stop $OTHER_CONTAINER
        docker rm $OTHER_CONTAINER
    else
        echo "No SIP containers found running"
    fi
fi

# 3. Create fixed docker-compose configuration
echo "3. Creating fixed docker-compose configuration..."

cat > docker-compose-fixed.yml << 'EOF'
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    container_name: voice-agent-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    command: redis-server --bind 0.0.0.0
    volumes:
      - redis_data:/data

  livekit-sip:
    build: 
      context: .
      dockerfile: Dockerfile
    container_name: livekit-sip-monkhub-prod
    restart: unless-stopped
    ports:
      - "5170:5170/udp"
      - "8080:8080/tcp"
      - "9090:9090/tcp"
      - "6000-65531:6000-65531/udp"
    environment:
      - EXTERNAL_IP=40.81.229.194
      - LIVEKIT_API_KEY=d6212ffd426f199fe1759c6370c85155
      - LIVEKIT_API_SECRET=6a7b312f5643020c86ceeef8785824e01f6ab1bd35394db1abf9d62e900ae23e
      - SIP_USERNAME=00919240908080
      - SIP_PASSWORD=1234
      - REDIS_URL=redis://redis:6379
      - LIVEKIT_WS_URL=ws://40.81.229.194:7880
    depends_on:
      - redis
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 90s

volumes:
  redis_data:
    driver: local
EOF

echo "Docker compose file created successfully"

# 4. Start with explicit port mapping
echo "4. Starting services with explicit port mapping..."
docker-compose -f docker-compose-fixed.yml up -d

# Wait a moment for services to start
echo "Waiting 30 seconds for services to start..."
sleep 30

# 5. Check if services are running
echo "5. Checking if services are running..."
docker ps
echo ""
echo "=== Redis Logs ==="
docker logs voice-agent-redis --tail 20
echo ""
echo "=== SIP Service Logs ==="
docker logs livekit-sip-monkhub-prod --tail 20

# 6. Test connectivity
echo "6. Testing connectivity..."
echo "Testing health endpoint..."
curl -s http://localhost:8080/health || echo "Health check failed"

echo "Testing Redis..."
redis-cli ping || echo "Redis connection failed"

echo "Checking port bindings..."
netstat -tulpn | grep ':5170\|:6379\|:8080\|:9090' || echo "Some ports not bound"

echo ""
echo "=== Summary ==="
echo "All services should now be accessible on external IP: 40.81.229.194"
echo "Redis: 40.81.229.194:6379"
echo "SIP: 40.81.229.194:5170"
echo "Health: 40.81.229.194:8080"
echo "Metrics: 40.81.229.194:9090"