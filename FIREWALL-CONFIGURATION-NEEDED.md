# Server Firewall Configuration Required

## Current Status:
- ✅ Server is running (40.81.229.194)
- ✅ LiveKit accessible on port 7880
- ❌ Other services blocked by firewall

## REQUIRED: Open These Ports on Server

### Azure Network Security Group (if using Azure VM):
```bash
# Open required ports in Azure NSG
az network nsg rule create \
  --resource-group voice-agent-resource-group \
  --nsg-name voice-agent-server-nsg \
  --name SIP-Ports \
  --protocol Udp \
  --priority 1000 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 5170 \
  --access Allow

az network nsg rule create \
  --resource-group voice-agent-resource-group \
  --nsg-name voice-agent-server-nsg \
  --name Redis-Port \
  --protocol Tcp \
  --priority 1001 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 6379 \
  --access Allow

az network nsg rule create \
  --resource-group voice-agent-resource-group \
  --nsg-name voice-agent-server-nsg \
  --name Health-Metrics \
  --protocol Tcp \
  --priority 1002 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 8080,9090 \
  --access Allow

az network nsg rule create \
  --resource-group voice-agent-resource-group \
  --nsg-name voice-agent-server-nsg \
  --name RTP-Ports \
  --protocol Udp \
  --priority 1003 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 6000-65531 \
  --access Allow
```

### OR Server UFW Firewall (if using Ubuntu):
```bash
# SSH into your server: ssh user@40.81.229.194
sudo ufw allow 5170/udp   # SIP
sudo ufw allow 6379/tcp   # Redis
sudo ufw allow 8080/tcp   # Health
sudo ufw allow 9090/tcp   # Metrics
sudo ufw allow 6000:65531/udp  # RTP
sudo ufw reload
```

### Verify Services are Running:
```bash
# Check services on server
sudo systemctl status redis-server
sudo systemctl status livekit
sudo netstat -tlnp | grep ':6379\|:7880\|:8080\|:9090'
sudo netstat -ulnp | grep ':5170'
```

## After Opening Ports:
1. Test connectivity again
2. Verify all services respond
3. Test MONKHUB SIP registration
4. Make test calls

## Current Working:
- LiveKit: ✅ Port 7880 accessible
- Your GitHub Actions deployment: ✅ Ready
- Azure Container Apps: ✅ Deployed

## Next Step:
Fix firewall/security group to allow all required ports!