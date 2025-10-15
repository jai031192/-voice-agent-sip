# LiveKit SIP - DevOps Deployment Package
**MONKHUB INNOVATIONS Integration for Azure**

## 🎯 Quick Overview
This package contains everything needed to deploy LiveKit SIP service on Azure for MONKHUB provider integration.

### What This Does
- **Receives SIP calls** from MONKHUB (27.107.220.6) on your Azure IP (40.81.229.194:5170)
- **Routes calls** to LiveKit video rooms where web participants can join
- **Handles audio** between SIP callers and web participants

## 📦 Package Contents
```
📁 livekit-sip-deployment/
├── 📄 Dockerfile                    # Complete container definition
├── 📄 docker-compose.yml           # Easy deployment orchestration
├── 📄 config.yaml                  # Production SIP service config
├── 📄 livekit-config.yaml         # Production LiveKit config
├── 📄 docker-entrypoint.sh        # Service startup orchestration
├── 📄 DEPLOYMENT-GUIDE.md         # Comprehensive deployment guide
├── 📄 quick-deploy.sh             # Automated deployment script
├── 📄 .env                        # Environment variables
└── 📄 README.md                   # This file
```

## ⚡ Quick Deployment (3 Steps)

### 1. Provision Azure VM
- **Required IP**: 40.81.229.194 (static)
- **VM Size**: Standard_B2s minimum
- **OS**: Ubuntu 20.04+
- **Ports**: 5170, 7880, 8080

### 2. Copy Files & Deploy
```bash
# Copy to Azure VM
scp -r livekit-sip-deployment/ azureuser@40.81.229.194:~/

# SSH and deploy
ssh azureuser@40.81.229.194
cd livekit-sip-deployment/
chmod +x quick-deploy.sh
./quick-deploy.sh
```

### 3. Verify
```bash
curl http://40.81.229.194:8080/health
```

## 🔧 Manual Deployment
If you prefer manual control:

```bash
# Install Docker (if needed)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Deploy with Docker Compose
docker-compose up -d

# Check status
docker ps
docker logs livekit-sip-monkhub
```

## 📊 Monitoring
- **Health Check**: http://40.81.229.194:8080/health
- **Service Logs**: `docker logs livekit-sip-monkhub`
- **System Status**: `docker ps` and `docker stats`

## 🧪 Testing
1. **Health Check**: Should return `200 OK`
2. **Port Check**: `netstat -tulpn | grep 5170`
3. **MONKHUB Test**: Coordinate test call to 9240908080

## ⚠️ Critical Requirements
- **Static IP**: 40.81.229.194 (cannot change - MONKHUB whitelisted)
- **Port 5170**: Must be accessible from 27.107.220.6 (MONKHUB SBC)
- **Firewall**: Allow inbound from MONKHUB SBC to port 5170

## 🆘 Emergency Support
```bash
# Restart service
docker-compose restart

# Full reset
docker-compose down && docker-compose up -d

# Check logs
docker logs -f livekit-sip-monkhub
```

## 📞 Provider Details
- **MONKHUB INNOVATIONS PRIVATE LIMITED**
- **Phone**: 9240908080
- **SBC IP**: 27.107.220.6
- **Credentials**: 00919240908080/1234

---
**For detailed instructions, see DEPLOYMENT-GUIDE.md**