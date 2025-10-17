# Final Firewall Fix - Run on your server (40.81.229.194)

echo "=== FINAL FIREWALL CONFIGURATION ==="

# Redis is working (6379) ✅
# LiveKit is working (7880) ✅
# Still need to open: 5170 (SIP), 8080 (Health), 9090 (Metrics)

# Option 1: UFW Firewall (Ubuntu)
echo "Opening remaining ports with UFW..."
sudo ufw allow 5170/udp   # SIP
sudo ufw allow 8080/tcp   # Health
sudo ufw allow 9090/tcp   # Metrics
sudo ufw reload
sudo ufw status

# Option 2: IPTables (if UFW not used)
echo "Alternative - IPTables rules..."
sudo iptables -A INPUT -p udp --dport 5170 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT  
sudo iptables -A INPUT -p tcp --dport 9090 -j ACCEPT
sudo iptables -L

# Test from server
echo "Testing from server localhost..."
curl -s http://localhost:8080/health
nc -zv localhost 5170

echo "=== AZURE NSG (if using Azure VM) ==="
echo "Also add these rules in Azure Portal:"
echo "- Port 5170/UDP - SIP"
echo "- Port 8080/TCP - Health"  
echo "- Port 9090/TCP - Metrics"

echo "=== VERIFICATION ==="
echo "After firewall changes, test from external:"
echo "Test-NetConnection -ComputerName 40.81.229.194 -Port 8080"
echo "Test-NetConnection -ComputerName 40.81.229.194 -Port 5170"