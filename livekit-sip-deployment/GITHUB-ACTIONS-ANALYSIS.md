# GitHub Actions CI/CD Pipeline Analysis & Instructions for LiveKit SIP Project

## Project Analysis Overview

Based on the current repository structure and configuration, this document provides comprehensive instructions for creating a GitHub Actions workflow that supports both local development and Azure production deployment.

## 1. PROJECT STRUCTURE ANALYSIS

### Detected Components:
- **Language**: Go (detected go.mod, go.sum files)
- **Application Type**: LiveKit SIP Service with Redis integration
- **Containerization**: Docker (Dockerfile, docker-compose.yml present)
- **Configuration**: YAML-based configs (config.yaml, livekit-config.yaml)
- **Provider Integration**: MONKHUB SIP provider
- **Database**: Redis for state management

### Key Files Identified:
```
/
├── go.mod, go.sum                    # Go dependencies
├── cmd/livekit-sip/                  # Main application entry point
├── pkg/                              # Go packages
├── sip/                             # SIP service executable
├── livekit-sip-deployment/          # Production deployment package
│   ├── Dockerfile                   # Multi-stage Docker build
│   ├── docker-compose.yml          # Service orchestration
│   ├── config.yaml                 # SIP service config
│   ├── livekit-config.yaml         # LiveKit server config
│   ├── .env                        # Environment variables
│   └── deploy-to-server.sh         # Manual deployment script
├── redis/                           # Local Redis installation
└── test files (*.ps1)              # PowerShell test scripts
```

## 2. DEPENDENCY ANALYSIS

### Go Dependencies (go.mod):
- LiveKit Protocol packages
- SIP/RTP handling libraries
- Redis client
- Audio processing (opus, soxr)
- CLI frameworks (urfave/cli)

### Runtime Dependencies:
- Redis server
- Audio codec libraries (opus, libsamplerate, soxr)
- Network utilities

### Build Dependencies:
- Go 1.24+
- CGO for audio libraries
- pkg-config
- build-essential tools

## 3. ENVIRONMENT CONFIGURATION

### Current Environment Variables (.env):
```bash
EXTERNAL_IP=40.81.229.194
LIVEKIT_API_KEY=API5DcPxqyBDHLr
LIVEKIT_API_SECRET=b9dgi6VEHsXf1zLKFWffHONECta5Xvfs5ejgdZhUoxPE
SIP_PROVIDER=MONKHUB_INNOVATIONS
SIP_USERNAME=00919240908080
SIP_PASSWORD=1234
```

### Configuration Mapping:
- **Local Environment**: Uses localhost addresses, development ports
- **Azure Environment**: Uses public IP (40.81.229.194), production settings

## 4. BUILD & TEST STRATEGY

### Build Process:
1. Go module download
2. CGO compilation with audio libraries
3. Static binary generation
4. Docker image creation
5. Multi-stage build optimization

### Test Strategy:
1. Unit tests (Go test)
2. Integration tests (service connectivity)
3. Docker container tests
4. Health check validation
5. SIP protocol compliance tests

## 5. DEPLOYMENT STRATEGY

### Local Deployment:
- Direct binary execution
- Local Docker compose
- Development configurations

### Azure Deployment:
- Container registry push
- Azure Container Instances or App Service
- Production configurations
- External IP binding
- Health monitoring

## 6. GITHUB ACTIONS WORKFLOW DESIGN

### Workflow Structure:
```yaml
name: LiveKit SIP CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  workflow_dispatch:
    inputs:
      deploy_environment:
        description: 'Deployment Environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production
          - local

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: livekit-sip-service
```

### Job Structure:
1. **code-quality** - Linting, formatting, security scanning
2. **test** - Unit tests, integration tests
3. **build** - Binary compilation, Docker image creation
4. **deploy-staging** - Deploy to staging environment
5. **deploy-production** - Deploy to production (manual approval)

## 7. REQUIRED GITHUB SECRETS

### Azure Authentication:
```
AZURE_CLIENT_ID          # Service Principal Client ID
AZURE_TENANT_ID          # Azure AD Tenant ID
AZURE_SUBSCRIPTION_ID    # Azure Subscription ID
AZURE_CLIENT_SECRET      # Service Principal Secret (or use OIDC)
```

### Container Registry:
```
REGISTRY_USERNAME        # Container registry username
REGISTRY_PASSWORD        # Container registry password
```

### Application Secrets:
```
LIVEKIT_API_KEY         # LiveKit API key
LIVEKIT_API_SECRET      # LiveKit API secret
SIP_USERNAME            # MONKHUB SIP username
SIP_PASSWORD            # MONKHUB SIP password
REDIS_PASSWORD          # Redis password (if secured)
```

### Environment Specific:
```
AZURE_EXTERNAL_IP       # Production external IP
STAGING_EXTERNAL_IP     # Staging external IP
AZURE_RESOURCE_GROUP    # Azure resource group name
AZURE_APP_SERVICE_NAME  # Azure App Service name
```

## 8. AZURE RESOURCES REQUIRED

### Infrastructure Components:
1. **Azure Container Registry** - Store Docker images
2. **Azure Container Instances** or **App Service** - Host application
3. **Azure Cache for Redis** - Managed Redis service
4. **Azure Virtual Network** - Network isolation
5. **Azure Application Gateway** - Load balancing and SSL
6. **Azure Monitor** - Logging and monitoring

### Network Configuration:
- **Public IP**: Static IP for SIP traffic (40.81.229.194)
- **NSG Rules**: Allow SIP (5170), HTTP (7880, 8080), Redis (6379)
- **DNS**: Optional custom domain setup

## 9. CONDITIONAL DEPLOYMENT LOGIC

### Environment Detection Strategy:
```yaml
# Detect environment based on:
# 1. Branch name (main = production, develop = staging)
# 2. Workflow dispatch input
# 3. Environment variables
# 4. Git tags (v1.0.0 = production release)

steps:
  - name: Determine Environment
    id: env
    run: |
      if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
        echo "environment=production" >> $GITHUB_OUTPUT
      elif [[ "${{ github.ref }}" == "refs/heads/develop" ]]; then
        echo "environment=staging" >> $GITHUB_OUTPUT
      else
        echo "environment=development" >> $GITHUB_OUTPUT
      fi
```

### Configuration Switching:
```yaml
# Use different config files based on environment
- name: Select Configuration
  run: |
    case "${{ steps.env.outputs.environment }}" in
      production)
        cp config/production.yaml config.yaml
        export EXTERNAL_IP="${{ secrets.AZURE_EXTERNAL_IP }}"
        ;;
      staging)
        cp config/staging.yaml config.yaml
        export EXTERNAL_IP="${{ secrets.STAGING_EXTERNAL_IP }}"
        ;;
      *)
        cp config/development.yaml config.yaml
        export EXTERNAL_IP="localhost"
        ;;
    esac
```

## 10. CACHING STRATEGY

### Go Module Cache:
```yaml
- name: Cache Go modules
  uses: actions/cache@v3
  with:
    path: ~/go/pkg/mod
    key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
    restore-keys: |
      ${{ runner.os }}-go-
```

### Docker Layer Cache:
```yaml
- name: Setup Docker Buildx
  uses: docker/setup-buildx-action@v2
  with:
    buildkitd-flags: --debug

- name: Cache Docker layers
  uses: actions/cache@v3
  with:
    path: /tmp/.buildx-cache
    key: ${{ runner.os }}-buildx-${{ github.sha }}
    restore-keys: |
      ${{ runner.os }}-buildx-
```

## 11. MATRIX TESTING STRATEGY

### Go Version Matrix:
```yaml
strategy:
  matrix:
    go-version: [1.21, 1.22, 1.23]
    os: [ubuntu-latest]
    # Add windows-latest for cross-platform testing if needed
```

### Environment Matrix:
```yaml
strategy:
  matrix:
    environment: [development, staging]
    include:
      - environment: development
        config_file: config/development.yaml
        external_ip: localhost
      - environment: staging
        config_file: config/staging.yaml
        external_ip: staging.example.com
```

## 12. MONITORING & NOTIFICATIONS

### Health Checks:
```yaml
- name: Health Check
  run: |
    # Wait for service to start
    sleep 30
    
    # Check service endpoints
    curl -f http://localhost:8080/health || exit 1
    curl -f http://localhost:7880 || exit 1
    
    # Test Redis connection
    redis-cli ping || exit 1
```

### Notifications:
```yaml
- name: Notify Deployment Status
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## 13. SECURITY CONSIDERATIONS

### Secret Scanning:
```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
    format: 'sarif'
    output: 'trivy-results.sarif'
```

### OIDC Authentication (Recommended):
```yaml
permissions:
  id-token: write
  contents: read

- name: Azure Login
  uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## 14. ROLLBACK STRATEGY

### Blue-Green Deployment:
```yaml
- name: Deploy with Zero Downtime
  run: |
    # Deploy to staging slot
    az containerapp update \
      --name ${{ env.APP_NAME }}-staging \
      --image ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
    
    # Health check staging
    curl -f https://${{ env.APP_NAME }}-staging.azurecontainerapps.io/health
    
    # Swap to production
    az containerapp revision set-active \
      --name ${{ env.APP_NAME }} \
      --revision-name ${{ github.sha }}
```

## 15. LOCAL TO AZURE MIGRATION CHECKLIST

### Pre-Migration:
- [ ] Azure subscription and resource group created
- [ ] Service principal with appropriate permissions
- [ ] Container registry configured
- [ ] Static public IP allocated (40.81.229.194)
- [ ] Network security groups configured
- [ ] DNS records updated (if using custom domain)

### Configuration Updates:
- [ ] Update external_ip from localhost to Azure public IP
- [ ] Configure Redis connection string for Azure Cache
- [ ] Update CORS origins for web clients
- [ ] Set up Application Insights for monitoring
- [ ] Configure log aggregation

### Security Updates:
- [ ] Enable HTTPS/TLS certificates
- [ ] Configure authentication for management endpoints
- [ ] Set up network access restrictions
- [ ] Enable Azure Key Vault for secrets management
- [ ] Configure backup and disaster recovery

## 16. WORKFLOW FILE LOCATION

The complete workflow should be saved as:
```
.github/workflows/ci-cd-azure.yml
```

This file will contain all the job definitions, environment configurations, and deployment logic needed to support both local development and Azure production deployment.

## 17. POST-DEPLOYMENT VERIFICATION

### Automated Tests:
```yaml
- name: Post-Deployment Tests
  run: |
    # Test SIP connectivity
    sip-test-client --server ${{ env.EXTERNAL_IP }}:5170
    
    # Test LiveKit API
    curl -f http://${{ env.EXTERNAL_IP }}:7880/rooms
    
    # Test health endpoints
    curl -f http://${{ env.EXTERNAL_IP }}:8080/health
    
    # Load testing (optional)
    # artillery run load-test.yml
```

This comprehensive analysis provides the foundation for creating a robust CI/CD pipeline that supports your LiveKit SIP service from local development through Azure production deployment.