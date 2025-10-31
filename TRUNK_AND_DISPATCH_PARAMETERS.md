# SIP Trunk and Dispatch Rule Creation Parameters

# SIP Trunk and Dispatch Rule Creation Parameters (CORRECTED)

## 📞 TRUNK CREATION - JSON FORMAT

### Command:
```bash
/usr/local/bin/lk sip inbound create \
    --url "${LIVEKIT_URL}" \
    --api-key "${LIVEKIT_API_KEY}" \
    --api-secret "${LIVEKIT_API_SECRET}" \
    /tmp/trunk.json
```

# SIP Trunk and Dispatch Rule Creation Parameters (FINAL CORRECT VERSION)

## 📞 TRUNK CREATION - OFFICIAL FORMAT

### Command:
```bash
/usr/local/bin/lk sip inbound create \
    --url "${LIVEKIT_URL}" \
    --api-key "${LIVEKIT_API_KEY}" \
    --api-secret "${LIVEKIT_API_SECRET}" \
    /tmp/trunk.json
```

### Trunk JSON (/tmp/trunk.json) - Based on Official Docs:
```json
{
  "trunk": {
    "name": "MONKHUB Inbound SIP Trunk",
    "numbers": [
      "+919240908080"
    ],
    "krispEnabled": true,
    "allowedAddresses": ["27.107.220.6"],
    "authUsername": "00919240908080",
    "authPassword": "1234"
  }
}
```

## 📋 DISPATCH RULE CREATION - OFFICIAL FORMAT

### Command:
```bash
/usr/local/bin/lk sip dispatch create \
    --url "${LIVEKIT_URL}" \
    --api-key "${LIVEKIT_API_KEY}" \
    --api-secret "${LIVEKIT_API_SECRET}" \
    /tmp/dispatch.json
```

### Dispatch JSON (/tmp/dispatch.json) - Based on Official Docs:
```json
{
  "dispatch_rule": {
    "rule": {
      "dispatchRuleIndividual": {
        "roomPrefix": "call-"
      }
    },
    "name": "MONKHUB Individual Room Dispatch",
    "roomConfig": {
      "agents": [{
        "agentName": "voice-agent",
        "metadata": "MONKHUB inbound call handler"
      }]
    }
  }
}
```

## 🎯 KEY INSIGHTS FROM OFFICIAL DOCUMENTATION

### **Trunk Parameters Explained:**
- `name`: Human readable name for the trunk
- `numbers`: Array of phone numbers this trunk handles
- `krispEnabled`: Enable noise cancellation (boolean)
- `allowedAddresses`: Array of IP addresses allowed to send calls (optional)
- `authUsername`: SIP authentication username (optional, provider dependent)
- `authPassword`: SIP authentication password (optional, provider dependent)

### **Dispatch Rule Parameters Explained:**
- `rule.dispatchRuleIndividual.roomPrefix`: Prefix for individual room creation
- `name`: Human readable name for the dispatch rule
- `roomConfig.agents`: Array of agents to dispatch to created rooms
- **IMPORTANT**: When `trunk_ids` is omitted, dispatch rule matches ALL trunks

### **Linking Logic:**
- ✅ **No explicit trunk linking needed**: Dispatch rules match all trunks by default
- ✅ **Automatic matching**: When a call comes to any trunk, it uses available dispatch rules
- ✅ **Individual rooms**: Each call creates `call-<unique-id>` rooms
- ✅ **Agent dispatch**: `voice-agent` automatically joins each new room

## 🔄 PROCESS FLOW

1. **Trunk Creation**: Creates an inbound SIP trunk that can receive calls
   - Returns a `TRUNK_ID` that's used in dispatch rule
   
2. **Dispatch Rule Creation**: Links the trunk to room creation logic
   - Uses the `TRUNK_ID` from step 1
   - Configures individual room strategy with "call-" prefix
   - Each incoming call creates a new room: call-<unique-id>

## 📊 ENVIRONMENT VARIABLES USED

```bash
LIVEKIT_URL="http://localhost:7880"
LIVEKIT_API_KEY="108378f337bbab3ce4e944554bed555a"
LIVEKIT_API_SECRET="2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d"
PHONE_NUMBER="+919240908080"
```

## 🎯 EXPECTED RESULTS

### Successful Trunk Creation:
```json
{
  "sip_trunk_id": "trunk_abc123",
  "name": "MONKHUB Inbound SIP Trunk",
  "numbers": ["+919240908080"],
  "auth_username": "00919240908080"
}
```

### Successful Dispatch Rule Creation:
```json
{
  "sip_dispatch_rule_id": "dispatch_xyz789",
  "name": "Individual Room Dispatch",
  "trunk_ids": ["trunk_abc123"],
  "rule": {
    "dispatchRuleIndividual": {
      "roomPrefix": "call-"
    }
  }
}
```

## ⚠️ IMPORTANT NOTES

1. **Order Matters**: Trunk must be created first to get TRUNK_ID
2. **Authentication**: Uses MONKHUB credentials (00919240908080/1234)
3. **Room Strategy**: Individual rooms (call-<unique-id>) for each call
4. **Phone Number**: +919240908080 (MONKHUB number, not Twilio)