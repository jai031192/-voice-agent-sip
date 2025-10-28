# Instructions to Set Up Your Own GitHub Repository

## Option 1: Using GitHub Web Interface (Recommended)

1. **Go to GitHub**: https://github.com
2. **Click "New repository"** (green button or plus icon)
3. **Repository details**:
   - **Name**: `voice-agent-sip`
   - **Description**: `Voice Agent SIP Service with LiveKit and MONKHUB Integration`
   - **Visibility**: Private (recommended) or Public
   - **Initialize**: Don't check any boxes (we already have files)

4. **Click "Create repository"**

5. **Copy the repository URL** (it will be something like):
   ```
   https://github.com/YOUR_USERNAME/voice-agent-sip.git
   ```

## Option 2: Using GitHub CLI (if you have it installed)

```bash
gh repo create voice-agent-sip --private --description "Voice Agent SIP Service"
```

## Next Steps After Repository Creation

Run these commands in PowerShell:

```powershell
# Remove old remote
git remote remove origin

# Add your new repository
git remote add origin https://github.com/YOUR_USERNAME/voice-agent-sip.git

# Push to your repository
git push -u origin main
```

## Required GitHub Secrets

After pushing, go to your repository → Settings → Secrets and variables → Actions

Add these secrets:

```
AZURE_CLIENT_ID: <your-service-principal-id>
AZURE_TENANT_ID: <your-azure-tenant-id>
LIVEKIT_API_KEY: 108378f337bbab3ce4e944554bed555a
LIVEKIT_API_SECRET: 2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d
SIP_USERNAME: 00919240908080
SIP_PASSWORD: 1234
```

## Azure Service Principal Setup

You'll need to create an Azure Service Principal for GitHub Actions:

```bash
az ad sp create-for-rbac --name "voice-agent-github-actions" --role contributor --scopes /subscriptions/00c9672f-2264-4555-a212-f212d309f897 --sdk-auth
```

This will give you the AZURE_CLIENT_ID and AZURE_TENANT_ID values.