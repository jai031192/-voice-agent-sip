# Local Trunk and Dispatch Creation Script for Windows
# Make sure you have installed LiveKit CLI first using install-livekit-cli-windows.ps1

Write-Host "🚀 Creating SIP Trunk and Dispatch Rule locally..." -ForegroundColor Green

# Configuration - Updated with your server details
$LIVEKIT_URL = "http://40.81.229.194:7880"   # Your Azure server IP
$LIVEKIT_API_KEY = "108378f337bbab3ce4e944554bed555a"
$LIVEKIT_API_SECRET = "2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d"
$TWILIO_NUMBER = "+13074606119"               # Your Twilio number

Write-Host "📋 Configuration:" -ForegroundColor Cyan
Write-Host "  LiveKit URL: $LIVEKIT_URL"
Write-Host "  Twilio Number: $TWILIO_NUMBER"
Write-Host ""

# Check if CLI is installed
try {
    $version = & lk --version 2>&1
    Write-Host "✅ LiveKit CLI found: $version" -ForegroundColor Green
} catch {
    Write-Host "❌ LiveKit CLI not found. Please install it first using install-livekit-cli-windows.ps1" -ForegroundColor Red
    exit 1
}

# Set environment variables
$env:LIVEKIT_URL = $LIVEKIT_URL
$env:LIVEKIT_API_KEY = $LIVEKIT_API_KEY
$env:LIVEKIT_API_SECRET = $LIVEKIT_API_SECRET

Write-Host "🔧 Environment variables set" -ForegroundColor Yellow

# Create INBOUND trunk JSON
$trunkJson = @{
    "sip_trunk_id" = "monkhub-inbound-trunk-001"
    "kind" = "TRUNK_INBOUND"
    "inbound_addresses" = @("27.107.220.6")     # Your SIP provider's IP
    "outbound_address" = ""
    "outbound_number" = ""
    "inbound_numbers_regex" = @()
    "inbound_numbers" = @("+919240908080")       # Your phone number
    "inbound_username" = "00919240908080"        # Your SIP username
    "inbound_password" = "1234"                  # Your SIP password
    "outbound_username" = ""
    "outbound_password" = ""
    "name" = "MONKHUB Inbound SIP Trunk"
    "metadata" = ""
} | ConvertTo-Json -Depth 10

$dispatchJson = @{
    "dispatch_rule_id" = "monkhub-dispatch-individual"
    "rule" = @{
        "dispatchRuleIndividual" = @{
            "roomPrefix" = "call-"
            "pin" = ""
            "roomConfig" = @{
                "name" = ""
                "emptyTimeout" = 300
                "maxParticipants" = 10
                "metadata" = ""
            }
        }
    }
    "trunk_ids" = @("monkhub-inbound-trunk-001")
    "hidePhoneNumber" = $false
    "inboundNumbers" = @("+919240908080")
    "name" = "Individual Room Dispatch"
    "metadata" = ""
} | ConvertTo-Json -Depth 10

Write-Host "📝 JSON configurations created" -ForegroundColor Yellow

# Save JSON to temp files
$trunkFile = "$env:TEMP\trunk.json"
$dispatchFile = "$env:TEMP\dispatch.json"

$trunkJson | Out-File -FilePath $trunkFile -Encoding UTF8
$dispatchJson | Out-File -FilePath $dispatchFile -Encoding UTF8

Write-Host "💾 JSON files saved:" -ForegroundColor Yellow
Write-Host "  Trunk: $trunkFile"
Write-Host "  Dispatch: $dispatchFile"

Write-Host ""
Write-Host "🔍 Trunk JSON Content:" -ForegroundColor Cyan
Get-Content $trunkFile | Write-Host

Write-Host ""
Write-Host "🔍 Dispatch JSON Content:" -ForegroundColor Cyan
Get-Content $dispatchFile | Write-Host

Write-Host ""
Write-Host "🚀 Creating SIP Trunk..." -ForegroundColor Green
try {
    $trunkResult = & lk sip create-sip-trunk --from-file $trunkFile 2>&1
    Write-Host "✅ Trunk creation result:" -ForegroundColor Green
    Write-Host $trunkResult
} catch {
    Write-Host "❌ Trunk creation failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    
    # Try alternative syntax
    Write-Host "🔄 Trying alternative CLI syntax..." -ForegroundColor Yellow
    try {
        $trunkResult = & lk sip trunk create --from-file $trunkFile 2>&1
        Write-Host "✅ Alternative syntax worked:" -ForegroundColor Green
        Write-Host $trunkResult
    } catch {
        Write-Host "❌ Alternative syntax also failed:" -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
}

Write-Host ""
Write-Host "🚀 Creating Dispatch Rule..." -ForegroundColor Green
try {
    $dispatchResult = & lk sip create-sip-dispatch-rule --from-file $dispatchFile 2>&1
    Write-Host "✅ Dispatch creation result:" -ForegroundColor Green
    Write-Host $dispatchResult
} catch {
    Write-Host "❌ Dispatch creation failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    
    # Try alternative syntax
    Write-Host "🔄 Trying alternative CLI syntax..." -ForegroundColor Yellow
    try {
        $dispatchResult = & lk sip dispatch create --from-file $dispatchFile 2>&1
        Write-Host "✅ Alternative syntax worked:" -ForegroundColor Green
        Write-Host $dispatchResult
    } catch {
        Write-Host "❌ Alternative syntax also failed:" -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
}

Write-Host ""
Write-Host "📋 Listing existing trunks and dispatch rules..." -ForegroundColor Cyan
try {
    Write-Host "🔍 SIP Trunks:" -ForegroundColor Yellow
    & lk sip list-sip-trunk 2>&1 | Write-Host
} catch {
    try {
        & lk sip trunk list 2>&1 | Write-Host
    } catch {
        Write-Host "❌ Could not list trunks"
    }
}

try {
    Write-Host "🔍 Dispatch Rules:" -ForegroundColor Yellow
    & lk sip list-sip-dispatch-rule 2>&1 | Write-Host
} catch {
    try {
        & lk sip dispatch list 2>&1 | Write-Host
    } catch {
        Write-Host "❌ Could not list dispatch rules"
    }
}

Write-Host ""
Write-Host "🧹 Cleaning up temporary files..." -ForegroundColor Yellow
Remove-Item $trunkFile -Force
Remove-Item $dispatchFile -Force

Write-Host ""
Write-Host "✅ Script completed!" -ForegroundColor Green
Write-Host "Please check the output above for any errors" -ForegroundColor Cyan