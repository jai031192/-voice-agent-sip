# LiveKit SIP Service - Azure Deployment Guide
**MONKHUB INNOVATIONS PRIVATE LIMITED Integration**

## 📋 Project Overview
- **Purpose**: Route SIP calls from MONKHUB provider to LiveKit video rooms
- **Provider**: MONKHUB INNOVATIONS (Mumbai Circle)
- **Phone Number**: 9240908080
- **Integration**: Cloud SIP with INT-PHONY

## 🏗️ Infrastructure Requirements

### Azure Requirements
- **Static IP**: `40.81.229.194` ⚠️ **CRITICAL - Cannot change**
- **Location**: East US (or preferred region)
- **VM Size**: Standard_B2s (2 vCPU, 4GB RAM) minimum
- **OS**: Ubuntu 20.04+ LTS
- **Storage**: 20GB SSD minimum

### Network Configuration
```yaml
Required_Ports:
  - 5170/tcp,udp  # SIP signaling (MONKHUB → Your service)
  - 7880/tcp      # LiveKit API/WebSocket
  - 8080/tcp      # Health monitoring
  - 6000-6100/udp # RTP media streams (subset)
  - 50000-50100/udp # LiveKit WebRTC (subset)

Firewall_Rules:
  Inbound:
    - Source: 27.107.220.6 (TATA SBC)
    - Destination: 40.81.229.194:5170
    - Protocol: TCP/UDP
  Outbound: 
    - Allow all (for WebRTC STUN/TURN)
```

### MONKHUB Provider Details
```yaml
Provider_Info:
  Company: "MONKHUB INNOVATIONS PRIVATE LIMITED"
  Circle: "Mumbai"
  Product: "Cloud SIP with INT-PHONY"
  
Network_Config:
  Customer_IP: "40.81.229.194"     # Your Azure static IP
  SBC_IP: "27.107.220.6"          # MONKHUB server
  TSI: "INT-MU-SBC06-9345"
  Source_Port: 5060               # MONKHUB sends from
  Destination_Port: 5170          # You receive on
  
Credentials:
  Username: "00919240908080"
  Password: "1234"
  Phone_Number: "9240908080"
  
Technical_Specs:
  Channels: 10
  Audio_Codec: "G711 Alaw only"
  RTP_Port_Range: "6000-65531"
```

## 🚀 Deployment Steps

### Step 1: Provision Azure Resources
```bash
# Create resource group
az group create --name rg-livekit-sip --location eastus

# Create VM with static IP (40.81.229.194 must be pre-allocated)
az vm create \
  --resource-group rg-livekit-sip \
  --name vm-livekit-sip \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --size Standard_B2s \
  --public-ip-address 40.81.229.194 \
  --public-ip-address-allocation static

# Configure firewall
az vm open-port --resource-group rg-livekit-sip --name vm-livekit-sip --port 5170 --priority 1000
az vm open-port --resource-group rg-livekit-sip --name vm-livekit-sip --port 7880 --priority 1001
az vm open-port --resource-group rg-livekit-sip --name vm-livekit-sip --port 8080 --priority 1002
```

### Step 2: Install Docker
```bash
# SSH to VM
ssh azureuser@40.81.229.194

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Step 3: Deploy Application
```bash
# Copy deployment files to VM
scp -r livekit-sip-deployment/ azureuser@40.81.229.194:~/

# SSH to VM and deploy
ssh azureuser@40.81.229.194
cd livekit-sip-deployment/
docker-compose up -d
```

### Step 4: Verify Deployment
```bash
# Check container status
docker ps

# Check health
curl http://localhost:8080/health
curl http://40.81.229.194:8080/health

# Check logs
docker logs livekit-sip-monkhub

# Test SIP port
netstat -tulpn | grep 5170
```

## 📊 Monitoring & Operations

### Health Monitoring
- **Health URL**: `http://40.81.229.194:8080/health`
- **Expected Response**: `200 OK`
- **Check Frequency**: Every 30 seconds

### Key Logs to Monitor
```bash
# Container logs
docker logs -f livekit-sip-monkhub

# System logs
sudo journalctl -u docker -f

# Network connections
netstat -an | grep -E "5170|7880"
```

### Common Operations
```bash
# Restart service
docker-compose restart

# Update configuration
# Edit config files and restart:
docker-compose down
docker-compose up -d

# Scale if needed (not applicable for SIP)
# View resource usage
docker stats

# Backup configuration
tar -czf livekit-sip-backup-$(date +%Y%m%d).tar.gz livekit-sip-deployment/
```

## 🧪 Testing Guide

### Internal Testing
```bash
# 1. Health check
curl http://40.81.229.194:8080/health

# 2. LiveKit API test
curl http://40.81.229.194:7880

# 3. SIP port test
telnet 40.81.229.194 5170
```

### MONKHUB Integration Testing
1. **Coordinate with MONKHUB** to test calls to 9240908080
2. **Monitor logs** during test calls
3. **Join LiveKit room** `monkhub-sip-room` via web client
4. **Test audio** bidirectional communication

### Expected Call Flow
```
1. External caller dials 9240908080
2. MONKHUB routes call to 40.81.229.194:5170
3. SIP service accepts and authenticates call
4. Call routed to LiveKit room "monkhub-sip-room"
5. Web participants join room to interact with caller
6. Bidirectional audio between SIP caller and web participants
```

## 🔧 Troubleshooting

### Common Issues
| Issue | Symptoms | Solution |
|-------|----------|----------|
| SIP calls not received | No logs on port 5170 | Check firewall rules |
| Authentication failed | SIP 401/403 errors | Verify credentials in config |
| No audio | Call connects but silent | Check RTP port range |
| Service crashes | Container restarts | Check memory/CPU limits |

### Emergency Procedures
```bash
# Quick restart
docker-compose restart

# Full reset
docker-compose down
docker system prune -f
docker-compose up -d

# Rollback (if you have backup)
docker-compose down
tar -xzf livekit-sip-backup-YYYYMMDD.tar.gz
docker-compose up -d
```

## 📞 Support Contacts
- **SIP Provider**: MONKHUB INNOVATIONS
- **Critical Requirements**: Static IP 40.81.229.194
- **Emergency Port**: 5170 (must remain accessible)

## ✅ Deployment Checklist
- [ ] Azure VM provisioned with static IP 40.81.229.194
- [ ] Docker and Docker Compose installed
- [ ] Firewall rules configured (5170, 7880, 8080)
- [ ] Application deployed via docker-compose
- [ ] Health check returns 200 OK
- [ ] SIP port 5170 listening
- [ ] MONKHUB notified of deployment
- [ ] Test call scheduled with MONKHUB
- [ ] Monitoring alerts configured