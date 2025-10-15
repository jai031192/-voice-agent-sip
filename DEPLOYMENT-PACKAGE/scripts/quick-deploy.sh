#!/bin/bash

# Quick Deploy Script for LiveKit SIP on Azure
# Usage: ./quick-deploy.sh [azure-vm-ip]

AZURE_IP=${1:-40.81.229.194}
DEPLOYMENT_DIR="livekit-sip-deployment"

echo "🚀 LiveKit SIP Quick Deployment to Azure"
echo "Target IP: $AZURE_IP"

# Check if we're on the Azure VM or local machine
if [[ "$(curl -s ifconfig.me)" == "$AZURE_IP" ]]; then
    echo "📍 Deploying locally on Azure VM"
    
    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        echo "🔧 Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        sudo usermod -aG docker $USER
        
        # Install Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        echo "🔄 Please log out and back in, then run this script again"
        exit 0
    fi
    
    # Deploy
    echo "🚀 Starting deployment..."
    cd $DEPLOYMENT_DIR
    docker-compose up -d
    
    echo "⏳ Waiting for services to start..."
    sleep 30
    
    # Verify
    echo "🧪 Testing deployment..."
    if curl -f http://localhost:8080/health; then
        echo "✅ Deployment successful!"
        echo "🌐 Service available at: http://$AZURE_IP:8080/health"
        echo "📞 SIP endpoint: $AZURE_IP:5170"
        echo "🎥 LiveKit API: http://$AZURE_IP:7880"
    else
        echo "❌ Health check failed"
        echo "📋 Check logs: docker logs livekit-sip-monkhub"
    fi
    
else
    echo "📤 Deploying remotely to Azure VM"
    
    # Copy files to Azure VM
    echo "📂 Copying files to Azure VM..."
    scp -r $DEPLOYMENT_DIR/ azureuser@$AZURE_IP:~/
    
    # Remote deployment
    echo "🚀 Starting remote deployment..."
    ssh azureuser@$AZURE_IP "cd $DEPLOYMENT_DIR && chmod +x quick-deploy.sh && ./quick-deploy.sh $AZURE_IP"
fi