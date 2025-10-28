# GitHub Repository Setup Instructions for LiveKit SIP CI/CD

## Overview
This document provides step-by-step instructions to set up your GitHub repository with the CI/CD pipeline for deploying LiveKit SIP service to Azure.

## 1. Repository Structure Setup

### Create the .github directory structure:
```bash
mkdir -p .github/workflows
mkdir -p .github/ISSUE_TEMPLATE
mkdir -p .github/PULL_REQUEST_TEMPLATE
```

### Required files placement:
```
.github/
├── workflows/
│   └── ci-cd-azure.yml           # Main CI/CD pipeline
├── ISSUE_TEMPLATE/
│   └── bug_report.md
└── PULL_REQUEST_TEMPLATE/
    └── pull_request_template.md
```

## 2. GitHub Secrets Configuration

### Navigate to your repository Settings > Secrets and variables > Actions

### Azure Authentication Secrets:
```
AZURE_CLIENT_ID          = <service-principal-client-id>
AZURE_TENANT_ID          = <azure-ad-tenant-id>
AZURE_SUBSCRIPTION_ID    = <azure-subscription-id>
AZURE_CLIENT_SECRET      = <service-principal-secret>
```

### Azure Resources:
```
AZURE_RESOURCE_GROUP     = rg-livekit-sip
AZURE_EXTERNAL_IP        = 40.81.229.194
STAGING_EXTERNAL_IP      = <staging-environment-ip>
```

### Application Configuration:
```
LIVEKIT_API_KEY         = 108378f337bbab3ce4e944554bed555a
LIVEKIT_API_SECRET      = 2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d
SIP_USERNAME            = 00919240908080
SIP_PASSWORD            = 1234
```

### Optional Notifications:
```
SLACK_WEBHOOK_URL       = <slack-webhook-for-notifications>
```

## 3. Azure Service Principal Setup

### Create service principal with required permissions:
```bash
# Login to Azure
az login

# Create service principal
az ad sp create-for-rbac \
  --name "livekit-sip-github-actions" \
  --role contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/rg-livekit-sip \
  --sdk-auth

# Output will provide the secrets needed for GitHub
```

### Required Azure permissions:
- **Contributor** role on the resource group
- **AcrPush** role on container registry (if using ACR)
- **Container App Contributor** role for Container Apps

## 4. Environment Configuration Files

### Create environment-specific configs:

#### config-development.yaml:
```yaml
log_level: debug
api_key: 108378f337bbab3ce4e944554bed555a
api_secret: 2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d
ws_url: ws://localhost:7880
redis:
  address: localhost:6379
sip_port: 5170
bind_address: "0.0.0.0"
external_ip: "localhost"
```

#### config-staging.yaml:
```yaml
log_level: info
api_key: 108378f337bbab3ce4e944554bed555a
api_secret: 2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d
ws_url: ws://localhost:7880
redis:
  address: redis:6379
sip_port: 5170
bind_address: "0.0.0.0"
external_ip: "${STAGING_EXTERNAL_IP}"
```

#### config-production.yaml:
```yaml
log_level: info
log_requests: true
api_key: 108378f337bbab3ce4e944554bed555a
api_secret: 2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d
ws_url: ws://localhost:7880
redis:
  address: redis:6379
sip_port: 5170
bind_address: "0.0.0.0"
external_ip: "${AZURE_EXTERNAL_IP}"
```

## 5. Branch Protection Rules

### Set up branch protection for main branch:
1. Go to Settings > Branches
2. Add rule for `main` branch:
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - ✅ Required status checks:
     - `Code Quality & Security`
     - `Run Tests`
     - `Build Application`

### Status checks to enable:
- `code-quality`
- `test`
- `build`
- `docker` (for deployment branches)

## 6. Environment Setup in GitHub

### Create environments:
1. Go to Settings > Environments
2. Create environments:
   - **development** (no restrictions)
   - **staging** (optional reviewers)
   - **production** (required reviewers + protection rules)

### Production environment protection:
- ✅ Required reviewers: Add team leads
- ✅ Wait timer: 5 minutes
- ✅ Deployment branches: Only `main`

## 7. Container Registry Setup

### Option A: GitHub Container Registry (GHCR) - Recommended
```bash
# Already configured in workflow
# Uses GITHUB_TOKEN automatically
# Registry: ghcr.io
```

### Option B: Azure Container Registry (ACR)
```bash
# Create ACR
az acr create \
  --resource-group rg-livekit-sip \
  --name livekitsipregistry \
  --sku Standard

# Update workflow to use ACR instead of GHCR
# Add ACR credentials to GitHub secrets
```

## 8. Azure Infrastructure Setup

### Create Azure resources:
```bash
# Resource Group
az group create --name rg-livekit-sip --location eastus

# Container App Environment
az containerapp env create \
  --name livekit-sip-env \
  --resource-group rg-livekit-sip \
  --location eastus

# Production Container App
az containerapp create \
  --name livekit-sip-prod \
  --resource-group rg-livekit-sip \
  --environment livekit-sip-env \
  --image nginx:latest \
  --target-port 8080 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 3

# Staging Container App
az containerapp create \
  --name livekit-sip-staging \
  --resource-group rg-livekit-sip \
  --environment livekit-sip-env \
  --image nginx:latest \
  --target-port 8080 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 2
```

## 9. Workflow Triggers and Behavior

### Automatic triggers:
- **Push to main**: Deploys to production
- **Push to develop**: Deploys to staging
- **Pull requests**: Runs tests and builds
- **Feature branches**: Runs tests only

### Manual triggers:
- **Workflow dispatch**: Choose environment manually
- **Repository dispatch**: API-triggered deployments

### Environment-specific behavior:
```yaml
# Development (feature branches):
- Runs tests and builds
- No deployment
- Uses localhost configs

# Staging (develop branch):
- Full pipeline including deployment
- Uses staging external IP
- Optional load testing

# Production (main branch):
- Full pipeline with extra security checks
- Blue-green deployment
- Requires manual approval
- Automatic rollback on failure
```

## 10. Monitoring and Alerting

### Set up Azure Monitor:
```bash
# Create Application Insights
az monitor app-insights component create \
  --app livekit-sip-insights \
  --location eastus \
  --resource-group rg-livekit-sip \
  --application-type web

# Create Log Analytics Workspace
az monitor log-analytics workspace create \
  --workspace-name livekit-sip-logs \
  --resource-group rg-livekit-sip \
  --location eastus
```

### Configure alerts:
- Container health status
- Memory/CPU usage
- Failed deployments
- SIP service availability

## 11. Local Development Workflow

### Developer workflow:
1. Create feature branch from `develop`
2. Make changes and commit
3. Push branch - triggers test pipeline
4. Create PR to `develop` - runs full validation
5. Merge to `develop` - deploys to staging
6. Test on staging environment
7. Create PR from `develop` to `main`
8. Merge to `main` - deploys to production

### Local testing before push:
```bash
# Run tests locally
go test ./...

# Build and test Docker image
docker build -t livekit-sip:local .
docker run --rm livekit-sip:local --help

# Run linting
golangci-lint run
```

## 12. Troubleshooting Common Issues

### Pipeline failures:
1. **Build failures**: Check Go version compatibility
2. **Test failures**: Verify Redis connectivity in tests
3. **Docker build failures**: Check multi-stage build context
4. **Azure deployment failures**: Verify service principal permissions

### Debug commands:
```bash
# Check pipeline logs in GitHub Actions
# View Azure Container App logs
az containerapp logs show \
  --name livekit-sip-prod \
  --resource-group rg-livekit-sip

# Check service health
curl -f http://40.81.229.194:8080/health
```

## 13. Security Best Practices

### Secrets management:
- ✅ Use GitHub secrets for sensitive data
- ✅ Rotate secrets regularly
- ✅ Use Azure Key Vault for production secrets
- ✅ Enable secret scanning in repository

### Container security:
- ✅ Use non-root user in Docker
- ✅ Scan images with Trivy
- ✅ Keep base images updated
- ✅ Use distroless images when possible

### Network security:
- ✅ Configure NSG rules properly
- ✅ Use private networking where possible
- ✅ Enable HTTPS/TLS
- ✅ Implement proper CORS policies

## 14. Rollback Procedures

### Automatic rollback:
- Health check failures trigger automatic rollback
- Previous revision is automatically restored

### Manual rollback:
```bash
# List available revisions
az containerapp revision list \
  --name livekit-sip-prod \
  --resource-group rg-livekit-sip

# Rollback to specific revision
az containerapp revision set-active \
  --name livekit-sip-prod \
  --resource-group rg-livekit-sip \
  --revision-name <revision-name>
```

## 15. Performance Optimization

### Pipeline optimization:
- ✅ Use caching for Go modules and Docker layers
- ✅ Run jobs in parallel where possible
- ✅ Use matrix builds for cross-version testing
- ✅ Skip unnecessary steps based on file changes

### Resource optimization:
- Configure appropriate CPU/memory limits
- Use horizontal pod autoscaling
- Implement connection pooling
- Optimize Docker image sizes

This setup provides a complete CI/CD pipeline that supports both local development and Azure production deployment with proper security, monitoring, and rollback capabilities.