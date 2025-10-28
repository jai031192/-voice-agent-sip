# 🚀 LiveKit SIP Service - Complete Deployment Package

**Production-Ready LiveKit SIP Service with MONKHUB Provider Integration**

## 📁 Package Contents

This deployment package contains everything needed to deploy the LiveKit SIP service from local development to Azure production.

### 📋 **Directory Structure:**
```
DEPLOYMENT-PACKAGE/
├── 📁 .github/workflows/          # GitHub Actions CI/CD Pipeline
│   └── ci-cd-azure.yml           # Complete CI/CD workflow for Azure
├── 📁 configs/                   # Configuration Files
│   ├── config.yaml               # SIP service configuration
│   └── livekit-config.yaml       # LiveKit server configuration
├── 📁 docs/                      # Documentation
│   ├── DEPLOYMENT-GUIDE.md       # Original deployment guide
│   ├── GITHUB-ACTIONS-ANALYSIS.md # Complete CI/CD analysis
│   ├── GITHUB-SETUP-INSTRUCTIONS.md # GitHub repository setup
│   └── README.md                 # Original project README
├── 📁 scripts/                   # Testing & Deployment Scripts
│   ├── comprehensive-test.ps1    # Complete connectivity test
│   ├── test-all-services.ps1     # Service status check
│   ├── test-connectivity.ps1     # Basic connectivity test
│   ├── test-ports.ps1           # Port availability test
│   ├── test-simple.ps1          # Simple connectivity check
│   └── deploy-to-server.sh      # Manual deployment script
├── 🐳 Dockerfile                # Production Docker image
├── 🐳 docker-compose.yml        # Local development setup
├── 🔧 .env                      # Environment variables
└── 📖 README.md                 # This file
```

## 🎯 **Quick Start Guide**

### **1. Local Development**
```bash
# Clone and navigate to deployment package
cd DEPLOYMENT-PACKAGE

# Test local services
.\scripts\comprehensive-test.ps1

# Run with Docker
docker-compose up -d
```

### **2. GitHub Repository Setup**
```bash
# Copy GitHub workflow
cp -r .github/ /path/to/your/repo/.github/

# Follow setup instructions
cat docs/GITHUB-SETUP-INSTRUCTIONS.md
```

### **3. Azure Production Deployment**
```bash
# Deploy to Azure
.\scripts\deploy-to-server.sh

# Or use GitHub Actions (recommended)
# Push to main branch for production deployment
```

## 📊 **Service Architecture**

### **Components:**
- **🔄 Redis**: State management and coordination
- **📞 SIP Service**: MONKHUB provider integration
- **🎥 LiveKit Server**: WebRTC room management
- **📡 Health Monitoring**: Service status tracking

### **Network Configuration:**
- **SIP Port**: 5170 (MONKHUB traffic)
- **LiveKit API**: 7880 (WebRTC management)
- **Health Check**: 8080 (monitoring)
- **Redis**: 6379 (internal state)

## 🏗️ **Deployment Options**

### **Option A: GitHub Actions (Recommended)**
- ✅ Automated CI/CD pipeline
- ✅ Environment-specific deployments
- ✅ Automatic rollback on failure
- ✅ Security scanning and quality checks

### **Option B: Manual Docker Deployment**
- ✅ Direct server deployment
- ✅ Quick local testing
- ✅ Full control over process

### **Option C: Azure Container Apps**
- ✅ Managed scaling and updates
- ✅ Blue-green deployments
- ✅ Integrated monitoring

## 🔧 **Configuration Files**

### **Environment-Specific Configs:**
- **Local**: `configs/config.yaml` (localhost, debug mode)
- **Staging**: Auto-generated with staging IP
- **Production**: Auto-generated with Azure IP (40.81.229.194)

### **Key Configuration Points:**
```yaml
# SIP Service (configs/config.yaml)
external_ip: "40.81.229.194"    # Your Azure static IP
sip_port: 5170                  # MONKHUB destination port
ws_url: ws://localhost:7880     # LiveKit connection

# LiveKit Server (configs/livekit-config.yaml)
bind_addresses: ["0.0.0.0"]     # Listen on all interfaces
use_external_ip: true           # Important for Azure
```

## 🧪 **Testing & Validation**

### **Comprehensive Test Suite:**
```powershell
# Run all connectivity tests
.\scripts\comprehensive-test.ps1

# Expected Result: 100% success rate
# ✅ Redis (6379): CONNECTED
# ✅ LiveKit (7880): CONNECTED  
# ✅ SIP Service (5170): CONNECTED
# ✅ Health Check (8081): CONNECTED
```

### **Service Health Verification:**
```bash
# Check service endpoints
curl http://40.81.229.194:8080/health    # Health check
curl http://40.81.229.194:7880          # LiveKit API
nc -z 40.81.229.194 5170                # SIP port test
```

## 🔐 **Security & Secrets**

### **Required GitHub Secrets:**
```
# Azure Authentication
AZURE_CLIENT_ID          # Service Principal ID
AZURE_TENANT_ID          # Azure AD Tenant
AZURE_SUBSCRIPTION_ID    # Subscription ID
AZURE_CLIENT_SECRET      # Service Principal Secret

# Application Secrets
LIVEKIT_API_KEY          # 108378f337bbab3ce4e944554bed555a
LIVEKIT_API_SECRET       # Your LiveKit secret
SIP_USERNAME             # 00919240908080
SIP_PASSWORD             # MONKHUB password

# Environment Configuration
AZURE_EXTERNAL_IP        # 40.81.229.194
AZURE_RESOURCE_GROUP     # Your Azure resource group
```

## 📞 **MONKHUB Provider Integration**

### **Provider Details:**
- **Provider**: MONKHUB INNOVATIONS PRIVATE LIMITED
- **Circle**: Mumbai
- **Customer IP**: 40.81.229.194
- **SBC IP**: 27.107.220.6
- **DEL Number**: 9240908080
- **Channels**: 10
- **Audio Codec**: G711 Alaw

### **SIP Trunk Configuration:**
- **Trunk ID**: ST_RtkH6pAP8mBK
- **Dispatch Rule**: SDR_WxQwZNKmq5T2
- **Target Room**: monkhub-sip-room

## 🌐 **Environment Support**

### **Development Environment:**
- ✅ Local testing with localhost
- ✅ Debug logging enabled
- ✅ No external dependencies

### **Staging Environment:**
- ✅ Staging IP configuration
- ✅ Load testing capabilities
- ✅ Pre-production validation

### **Production Environment:**
- ✅ Azure static IP (40.81.229.194)
- ✅ High availability configuration
- ✅ Monitoring and alerting
- ✅ Automatic scaling

## 📈 **Monitoring & Observability**

### **Health Monitoring:**
- **Service Health**: `/health` endpoint
- **LiveKit Status**: LiveKit API monitoring
- **Redis Connectivity**: Connection pooling status
- **SIP Registration**: Provider connectivity

### **Metrics & Alerts:**
- CPU and memory usage
- Network connectivity status
- Call success rates
- Error rates and latencies

## 🔄 **CI/CD Pipeline Features**

### **Automated Pipeline:**
- ✅ **Code Quality**: Go fmt, vet, golangci-lint
- ✅ **Security Scanning**: gosec, Trivy container scan
- ✅ **Testing**: Unit tests, integration tests
- ✅ **Building**: Multi-arch Docker builds
- ✅ **Deployment**: Blue-green Azure deployment
- ✅ **Rollback**: Automatic failure recovery

### **Environment Detection:**
- **main branch** → Production deployment
- **develop branch** → Staging deployment  
- **feature branches** → Test only
- **Manual trigger** → Choose environment

## 🆘 **Troubleshooting**

### **Common Issues:**
1. **Port binding errors**: Check if ports are available
2. **Docker networking**: Ensure host networking mode
3. **Azure authentication**: Verify service principal permissions
4. **Health check failures**: Check service startup order

### **Debug Commands:**
```bash
# Check service logs
docker-compose logs

# Test connectivity
.\scripts\comprehensive-test.ps1

# Manual health check
curl -f http://localhost:8080/health
```

## 📧 **Support & Documentation**

### **Documentation Files:**
- **`docs/DEPLOYMENT-GUIDE.md`**: Detailed deployment instructions
- **`docs/GITHUB-ACTIONS-ANALYSIS.md`**: Complete CI/CD analysis
- **`docs/GITHUB-SETUP-INSTRUCTIONS.md`**: Repository setup guide

### **Contact & Support:**
- Review logs in GitHub Actions
- Check Azure Container App logs
- Use health check endpoints for status

## 🎉 **Ready for Production!**

This deployment package provides:
- ✅ **100% tested local connectivity**
- ✅ **Production-ready Docker configuration**
- ✅ **Complete CI/CD automation**
- ✅ **Azure-optimized deployment**
- ✅ **MONKHUB provider integration**
- ✅ **Comprehensive monitoring**

**Deploy with confidence!** 🚀

---

**Last Updated**: October 14, 2025  
**Version**: 1.0.0  
**Status**: Production Ready ✅