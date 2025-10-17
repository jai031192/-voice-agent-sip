# Server Verification Commands
# Run these on your VM (40.81.229.194) to check status

echo "=== CHECKING DOCKER STATUS AFTER FIX ==="

# 1. Check if containers are running
echo "1. Docker containers status:"
docker ps

# 2. Check specific containers
echo "2. Checking Redis container:"
docker logs voice-agent-redis --tail 10

echo "3. Checking SIP container:"
docker logs livekit-sip-monkhub-prod --tail 10

# 3. Check port bindings on the server
echo "4. Port bindings on server:"
netstat -tulpn | grep ':5170\|:6379\|:8080\|:9090'

# 4. Test connectivity from server itself
echo "5. Testing from server (localhost):"
curl -s http://localhost:8080/health && echo "Health: OK" || echo "Health: FAILED"
redis-cli ping && echo "Redis: OK" || echo "Redis: FAILED"

# 5. Check firewall status
echo "6. Firewall status:"
sudo ufw status

# 6. Check iptables
echo "7. IPTables rules:"
sudo iptables -L -n | grep -E "5170|6379|8080|9090"

# 7. Check Azure Network Security Group (if applicable)
echo "8. If using Azure VM, check NSG rules in Azure portal"
echo "Required ports: 5170/UDP, 6379/TCP, 8080/TCP, 9090/TCP"

echo "=== END VERIFICATION ==="