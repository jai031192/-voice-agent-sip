# GitHub Repository Setup Script
# Run this after creating your GitHub repository

Write-Host "=== Voice Agent SIP GitHub Repository Setup ===" -ForegroundColor Green
Write-Host ""

# Step 1: Get repository URL from user
$repoUrl = Read-Host "Enter your GitHub repository URL (e.g., https://github.com/yourusername/voice-agent-sip.git)"

if (-not $repoUrl) {
    Write-Host "Repository URL is required!" -ForegroundColor Red
    exit 1
}

Write-Host "Setting up repository: $repoUrl" -ForegroundColor Yellow

try {
    # Step 2: Update remote origin
    Write-Host "Updating git remote..." -ForegroundColor Cyan
    git remote set-url origin $repoUrl
    
    # Step 3: Push to new repository
    Write-Host "Pushing to your repository..." -ForegroundColor Cyan
    git push -u origin main
    
    Write-Host ""
    Write-Host "SUCCESS! Your code is now in GitHub!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Go to your repository: $repoUrl"
    Write-Host "2. Go to Settings > Secrets and variables > Actions"
    Write-Host "3. Add these repository secrets:" -ForegroundColor Cyan
    Write-Host "   - AZURE_CLIENT_ID" -ForegroundColor White
    Write-Host "   - AZURE_TENANT_ID" -ForegroundColor White
    Write-Host "   - LIVEKIT_API_KEY: d6212ffd426f199fe1759c6370c85155" -ForegroundColor White
    Write-Host "   - LIVEKIT_API_SECRET: 6a7b312f5643020c86ceeef8785824e01f6ab1bd35394db1abf9d62e900ae23e" -ForegroundColor White
    Write-Host "   - SIP_USERNAME: 00919240908080" -ForegroundColor White
    Write-Host "   - SIP_PASSWORD: 1234" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Push any change to main branch to trigger deployment!" -ForegroundColor Green
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure you've created the GitHub repository first!" -ForegroundColor Yellow
}