# Quick Fix Commands for VM - Run these on 40.81.229.194

# 1. First, check what's currently running
docker ps
docker logs <container-name>

# 2. Stop current container
docker stop <container-name>

# 3. Update your docker-compose.yml to fix the configuration
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
      - "5170:5170/udp"   # SIP
      - "8080:8080/tcp"   # Health
      - "9090:9090/tcp"   # Metrics
      - "6000-65531:6000-65531/udp"  # RTP
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

# 4. Start with explicit port mapping
docker-compose -f docker-compose-fixed.yml up -d

# 5. Check if services are running
docker ps
docker logs livekit-sip-monkhub-prod
docker logs voice-agent-redis

# 6. Test connectivity
curl http://localhost:8080/health
redis-cli ping
netstat -tulpn | grep ':5170\|:6379\|:8080'

echo "All services should now be accessible on external IP!"