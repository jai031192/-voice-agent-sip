#!/bin/bash

# Server UFW Firewall Fix - Run on 40.81.229.194

echo "=== UFW FIREWALL CONFIGURATION ==="

# Check current UFW status
echo "Current UFW status:"
sudo ufw status verbose

echo ""
echo "Opening required ports..."

# Open the missing ports
sudo ufw allow 5170/udp   # SIP
sudo ufw allow 8080/tcp   # Health  
sudo ufw allow 9090/tcp   # Metrics

# Reload UFW
sudo ufw reload

echo ""
echo "Updated UFW status:"
sudo ufw status verbose

echo ""
echo "=== PORT VERIFICATION ==="

# Check if ports are bound on server
echo "Checking port bindings:"
netstat -tulpn | grep ':5170\|:8080\|:9090'

echo ""
echo "Testing services locally:"

# Test health endpoint
echo "Testing health endpoint..."
curl -s http://localhost:8080/health && echo " - Health OK" || echo " - Health FAILED"

# Test if SIP port is listening
echo "Testing SIP port 5170..."
nc -zv localhost 5170 2>&1 | grep -q "succeeded" && echo " - SIP port OK" || echo " - SIP port not listening"

# Check Docker containers
echo ""
echo "Docker container status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=== READY FOR EXTERNAL TESTING ==="
echo "After this, test from Windows machine:"
echo "Test-NetConnection -ComputerName 40.81.229.194 -Port 8080"
echo "Test-NetConnection -ComputerName 40.81.229.194 -Port 5170"