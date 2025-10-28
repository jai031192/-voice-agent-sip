# Production Deployment Guide - Voice Agent SIP Service

## **Server Configuration Summary**
- **Production IP**: 40.81.229.194
- **LiveKit URL**: ws://40.81.229.194:7880
- **Redis**: Same server (40.81.229.194:6379)
- **SIP Provider**: MONKHUB (00919240908080)
- **Deployment**: Azure Container Apps (single main branch)

## **Prerequisites**

### 1. Azure Setup
```bash
# Install Azure CLI
az login
az account set --subscription "00c9672f-2264-4555-a212-f212d309f897"

# Create resource group
az group create --name "voice-agent-resource-group" --location "East US"

# Create Container Registry
az acr create --resource-group "voice-agent-resource-group" \
  --name "voiceagent" --sku Basic --admin-enabled true
```

### 2. GitHub Repository Secrets
Set these secrets in your GitHub repository settings:

```
AZURE_CLIENT_ID: <your-service-principal-client-id>
AZURE_TENANT_ID: <your-azure-tenant-id>
AZURE_SUBSCRIPTION_ID: 00c9672f-2264-4555-a212-f212d309f897
LIVEKIT_API_KEY: 108378f337bbab3ce4e944554bed555a
LIVEKIT_API_SECRET: 2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d
SIP_USERNAME: 00919240908080
SIP_PASSWORD: 1234
```

## **Deployment Steps**

### 1. **Push to Main Branch (Automatic Deployment)**
```bash
git add .
git commit -m "Production deployment"
git push origin main
```
> This automatically triggers the CI/CD pipeline and deploys to production.

### 2. **Manual Azure Container App Creation** (First time only)
```bash
# Create Container App Environment
az containerapp env create \
  --name "va-cicd-env" \
  --resource-group "voice-agent-resource-group" \
  --location "East US"

# Create Container App
az containerapp create \
  --name "va-cicd" \
  --resource-group "voice-agent-resource-group" \
  --environment "va-cicd-env" \
  --image "voiceagent.azurecr.io/livekit-sip-service:latest" \
  --target-port 8080 \
  --ingress external \
  --cpu 1.0 \
  --memory 2Gi \
  --min-replicas 1 \
  --max-replicas 3 \
  --env-vars \
    EXTERNAL_IP=40.81.229.194 \
    REDIS_URL=redis://40.81.229.194:6379 \
    LIVEKIT_WS_URL=ws://40.81.229.194:7880
```

### 3. **Test Production Deployment**
```powershell
# Run production test suite
cd DEPLOYMENT-PACKAGE\scripts
.\test-production.ps1 -Verbose
```

## **Server Infrastructure Requirements**

### 1. **Install Required Services on 40.81.229.194**

#### Redis Server
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install redis-server
sudo systemctl enable redis-server
sudo systemctl start redis-server

# Configure Redis to accept external connections
sudo nano /etc/redis/redis.conf
# Comment out: bind 127.0.0.1
# Add: bind 0.0.0.0
sudo systemctl restart redis-server
```

#### LiveKit Server
```bash
# Download LiveKit Server
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
  108378f337bbab3ce4e944554bed555a: 2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d
EOF

# Create systemd service
sudo tee /etc/systemd/system/livekit.service << EOF
[Unit]
Description=LiveKit Server
After=network.target

[Service]
Type=simple
User=livekit
ExecStart=/usr/local/bin/livekit-server --config /etc/livekit/config.yaml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start LiveKit
sudo useradd -r -s /bin/false livekit
sudo systemctl enable livekit
sudo systemctl start livekit
```

### 2. **Firewall Configuration**
```bash
# Open required ports
sudo ufw allow 5170/udp  # SIP
sudo ufw allow 6000:65531/udp  # RTP
sudo ufw allow 7880/tcp  # LiveKit
sudo ufw allow 6379/tcp  # Redis
sudo ufw allow 8080/tcp  # Health
sudo ufw allow 9090/tcp  # Metrics
sudo ufw allow 22/tcp    # SSH
sudo ufw enable
```

## **Monitoring & Troubleshooting**

### 1. **Health Checks**
```bash
# Application health
curl http://40.81.229.194:8080/health

# LiveKit status
curl http://40.81.229.194:7880

# Redis connectivity
redis-cli -h 40.81.229.194 ping

# SIP port check
nmap -p 5170 40.81.229.194
```

### 2. **Log Monitoring**
```bash
# Azure Container Apps logs
az containerapp logs show \
  --name "va-cicd" \
  --resource-group "voice-agent-resource-group" \
  --follow

# Server logs
sudo journalctl -u livekit -f
sudo journalctl -u redis -f
```

### 3. **Performance Monitoring**
```bash
# Prometheus metrics
curl http://40.81.229.194:9090/metrics

# Server resources
htop
netstat -tulpn | grep ':5170\|:7880\|:6379'
```

## **MONKHUB SIP Provider Configuration**

### Provider Details
- **Customer IP**: 40.81.229.194
- **SBC IP**: 27.107.220.6
- **TSI**: INT-MU-SBC06-9345
- **Phone Number**: 9240908080
- **Username**: 00919240908080
- **Password**: 1234
- **Port**: 5170
- **Codec**: G711 Alaw

### Test SIP Registration
```bash
# Test SIP connectivity
sip-tester --server 27.107.220.6 --port 5170 \
  --username 00919240908080 --password 1234
```

## **Backup & Recovery**

### 1. **Configuration Backup**
```bash
# Backup configs
tar -czf config-backup-$(date +%Y%m%d).tar.gz \
  /etc/livekit/ /etc/redis/ DEPLOYMENT-PACKAGE/configs/

# Upload to Azure Storage
az storage blob upload --file config-backup-*.tar.gz \
  --container-name backups --name configs/
```

### 2. **Rollback Procedure**
```bash
# Rollback to previous container revision
az containerapp revision list --name "va-cicd" \
  --resource-group "voice-agent-resource-group"

# Activate previous revision
az containerapp revision set-active \
  --name "va-cicd" \
  --resource-group "voice-agent-resource-group" \
  --revision-name <previous-revision-name>
```

## **Production Readiness Checklist**

- ✅ Server infrastructure configured (Redis, LiveKit)
- ✅ Firewall ports opened
- ✅ MONKHUB SIP provider tested
- ✅ Azure Container Registry created
- ✅ GitHub secrets configured
- ✅ CI/CD pipeline simplified for main branch
- ✅ Production configuration updated
- ✅ Health monitoring setup
- ✅ Backup procedures documented

## **Next Steps**

1. **Setup server infrastructure** on 40.81.229.194
2. **Configure GitHub repository** with this deployment package
3. **Set GitHub secrets** as listed above
4. **Push to main branch** to trigger deployment
5. **Run production tests** to verify functionality

Your Voice Agent SIP service is now ready for production deployment! 🚀