# Server Infrastructure Setup Guide
# Target Server: 40.81.229.194

## CRITICAL: You need to set up the actual server infrastructure

### Option 1: Azure VM Setup (Recommended)
```bash
# Create Azure VM for your infrastructure
az vm create \
  --resource-group voice-agent-resource-group \
  --name voice-agent-server \
  --image Ubuntu2004 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-address-allocation static \
  --size Standard_B2s

# Get the public IP (should be 40.81.229.194)
az vm show -d --resource-group voice-agent-resource-group --name voice-agent-server --query publicIps -o tsv
```

### Option 2: Use Existing Server
If you already have server 40.81.229.194, install these services:

#### 1. Install Redis
```bash
sudo apt update
sudo apt install redis-server -y
sudo systemctl enable redis-server
sudo systemctl start redis-server

# Configure Redis for external connections
sudo sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
sudo systemctl restart redis-server
```

#### 2. Install LiveKit Server
```bash
# Download and install LiveKit
wget https://github.com/livekit/livekit/releases/latest/download/livekit_linux_amd64
chmod +x livekit_linux_amd64
sudo mv livekit_linux_amd64 /usr/local/bin/livekit-server

# Create LiveKit config
sudo mkdir -p /etc/livekit
sudo tee /etc/livekit/config.yaml << EOF
port: 7880
bind_addresses:
  - 0.0.0.0
redis:
  address: localhost:6379
keys:
  d6212ffd426f199fe1759c6370c85155: 6a7b312f5643020c86ceeef8785824e01f6ab1bd35394db1abf9d62e900ae23e
EOF

# Create systemd service
sudo tee /etc/systemd/system/livekit.service << EOF
[Unit]
Description=LiveKit Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/livekit-server --config /etc/livekit/config.yaml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable livekit
sudo systemctl start livekit
```

#### 3. Configure Firewall
```bash
# Open required ports
sudo ufw allow 22/tcp     # SSH
sudo ufw allow 6379/tcp   # Redis
sudo ufw allow 7880/tcp   # LiveKit
sudo ufw allow 5170/udp   # SIP
sudo ufw allow 6000:65531/udp  # RTP
sudo ufw allow 8080/tcp   # Health
sudo ufw allow 9090/tcp   # Metrics
sudo ufw enable
```

## Current Status:
- ✅ GitHub Actions: DEPLOYED
- ✅ Azure Container Apps: READY
- ❌ Server Infrastructure: NEEDS SETUP
- ❌ Redis: NOT RUNNING
- ❌ LiveKit: NOT RUNNING

## Next Actions:
1. Set up server 40.81.229.194 with Redis + LiveKit
2. Test connectivity again
3. Verify MONKHUB SIP registration
4. Start making/receiving calls!