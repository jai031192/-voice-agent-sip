# 📋 LiveKit SIP Deployment Checklist

## Pre-Deployment Checklist

### ✅ **Local Testing Complete**
- [ ] All services running locally (Redis, LiveKit, SIP)
- [ ] Comprehensive test passed (100% success rate)
- [ ] Docker build successful
- [ ] Health endpoints responding
- [ ] SIP port accessibility confirmed

### ✅ **Azure Infrastructure Ready**
- [ ] Azure subscription and resource group created
- [ ] Service principal with required permissions
- [ ] Static public IP allocated (40.81.229.194)
- [ ] Container registry configured
- [ ] Network security groups configured

### ✅ **GitHub Repository Setup**
- [ ] Repository created with deployment package
- [ ] GitHub secrets configured (Azure auth, API keys)
- [ ] Branch protection rules enabled
- [ ] Environments created (staging, production)
- [ ] Workflow file in `.github/workflows/`

### ✅ **MONKHUB Provider Configuration**
- [ ] SIP trunk created (ST_RtkH6pAP8mBK)
- [ ] Dispatch rule configured (SDR_WxQwZNKmq5T2)
- [ ] Provider credentials verified
- [ ] Audio codec settings confirmed (G711 Alaw)

## Deployment Steps

### **Method 1: GitHub Actions (Recommended)**
1. [ ] Push code to `develop` branch (deploys to staging)
2. [ ] Test staging environment
3. [ ] Create PR from `develop` to `main`
4. [ ] Merge to `main` (deploys to production)
5. [ ] Verify production deployment

### **Method 2: Manual Docker Deployment**
1. [ ] Copy deployment package to server
2. [ ] Run `docker-compose up -d`
3. [ ] Verify all services started
4. [ ] Run health checks
5. [ ] Test SIP connectivity

## Post-Deployment Verification

### ✅ **Service Health Checks**
- [ ] Health endpoint: `http://40.81.229.194:8080/health`
- [ ] LiveKit API: `http://40.81.229.194:7880`
- [ ] SIP port: `nc -z 40.81.229.194 5170`
- [ ] All services responding correctly

### ✅ **MONKHUB Integration Testing**
- [ ] Test call to 9240908080
- [ ] Verify call routing to monkhub-sip-room
- [ ] Check audio quality (G711 Alaw)
- [ ] Confirm call completion

### ✅ **Monitoring Setup**
- [ ] Azure Monitor configured
- [ ] Health check alerts enabled
- [ ] Log aggregation working
- [ ] Performance metrics collecting

## Rollback Procedure (If Needed)

### **GitHub Actions Rollback**
1. [ ] Identify last known good revision
2. [ ] Automatic rollback triggers on health check failure
3. [ ] Manual rollback via Azure CLI if needed

### **Manual Rollback**
1. [ ] Stop current containers: `docker-compose down`
2. [ ] Restore previous configuration
3. [ ] Restart services: `docker-compose up -d`
4. [ ] Verify rollback successful

## Security Validation

### ✅ **Security Checks**
- [ ] Container security scan passed (Trivy)
- [ ] Secrets properly configured (not hardcoded)
- [ ] Network access restricted appropriately
- [ ] HTTPS/TLS configured (if applicable)
- [ ] Authentication mechanisms working

## Performance Validation

### ✅ **Performance Tests**
- [ ] Service startup time acceptable
- [ ] Memory usage within limits
- [ ] CPU usage normal under load
- [ ] Network latency acceptable
- [ ] Call quality meets requirements

## Documentation Update

### ✅ **Documentation Complete**
- [ ] Deployment guide updated
- [ ] Configuration documented
- [ ] Troubleshooting guide available
- [ ] Contact information current
- [ ] Version information updated

## Sign-off

- [ ] **Technical Lead**: Services deployed and tested
- [ ] **DevOps**: Infrastructure and monitoring ready
- [ ] **Product Owner**: Feature functionality verified
- [ ] **Security**: Security requirements met

**Deployment Date**: ________________  
**Deployed By**: ____________________  
**Version**: 1.0.0  
**Environment**: [ ] Staging [ ] Production

---

## Emergency Contacts

**Technical Issues**: Development Team  
**Infrastructure Issues**: DevOps Team  
**Provider Issues**: MONKHUB Support  
**Azure Issues**: Azure Support

## Success Criteria Met ✅

- [ ] All services running with 100% health
- [ ] MONKHUB integration working
- [ ] GitHub Actions pipeline operational
- [ ] Monitoring and alerting active
- [ ] Documentation complete

**Status**: [ ] ✅ SUCCESS [ ] ❌ ISSUES [ ] 🔄 IN PROGRESS