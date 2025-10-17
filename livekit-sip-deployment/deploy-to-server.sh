# LiveKit SIP Deployment Commands for Server

# ================================
# SERVER DEPLOYMENT INSTRUCTIONS
# ================================

# 1. PREPARE SERVER
echo "🚀 Preparing server for LiveKit SIP deployment..."
sudo apt update
sudo apt install -y docker.io docker-compose git curl

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# 2. COPY DEPLOYMENT FILES
echo "📁 Copy the livekit-sip-deployment folder to your server"
# scp -r livekit-sip-deployment/ user@40.81.229.194:/home/user/

# 3. DEPLOY THE STACK
cd livekit-sip-deployment/
echo "🐳 Starting LiveKit SIP services..."
docker-compose up -d

# 4. VERIFY DEPLOYMENT
echo "✅ Checking service status..."
docker-compose ps
docker-compose logs --tail=50

# 5. TEST ENDPOINTS
echo "🧪 Testing service endpoints..."
curl -f http://localhost:7880 && echo "✅ LiveKit API working"
curl -f http://localhost:8080/health && echo "✅ Health check working"

# 6. CHECK PORTS
echo "🔍 Verifying port accessibility..."
netstat -tlnp | grep -E '(5170|7880|8080|6379)'

# 7. EXTERNAL ACCESS TEST
echo "🌐 Testing external access..."
curl -f http://40.81.229.194:7880 && echo "✅ External LiveKit access working"
curl -f http://40.81.229.194:8080/health && echo "✅ External health check working"

echo "🎉 Deployment complete! Services should be accessible at:"
echo "   - SIP Service: 40.81.229.194:5170"
echo "   - LiveKit API: http://40.81.229.194:7880"
echo "   - Health Check: http://40.81.229.194:8080/health"
echo ""
echo "📞 Ready for MONKHUB testing on number: 9240908080"