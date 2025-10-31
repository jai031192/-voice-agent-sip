# SIP Trunk and Dispatch Rule Creation - TWILIO CONFIGURATION

## 📞 TWILIO TRUNK CREATION FORMAT

### Command:
```bash
/usr/local/bin/lk sip inbound create \
    --url "${LIVEKIT_URL}" \
    --api-key "${LIVEKIT_API_KEY}" \
    --api-secret "${LIVEKIT_API_SECRET}" \
    /tmp/trunk.json
```

### Twilio Trunk JSON (/tmp/trunk.json):
```json
{
  "trunk": {
    "name": "Twilio Inbound SIP Trunk",
    "numbers": [
      "+13074606119"
    ],
    "krispEnabled": true
  }
}
```

## 📋 TWILIO DISPATCH RULE CREATION FORMAT

### Command:
```bash
/usr/local/bin/lk sip dispatch create \
    --url "${LIVEKIT_URL}" \
    --api-key "${LIVEKIT_API_KEY}" \
    --api-secret "${LIVEKIT_API_SECRET}" \
    /tmp/dispatch.json
```

### Twilio Dispatch JSON (/tmp/dispatch.json):
```json
{
  "dispatch_rule": {
    "rule": {
      "dispatchRuleIndividual": {
        "roomPrefix": "call-"
      }
    },
    "name": "Twilio Individual Room Dispatch",
    "roomConfig": {
      "agents": [{
        "agentName": "voice-agent",
        "metadata": "Twilio inbound call handler"
      }]
    }
  }
}
```

## 🎯 TWILIO-SPECIFIC CONFIGURATION

### **Key Differences for Twilio:**
- ✅ **No authentication required**: Twilio Elastic SIP Trunking doesn't use username/password
- ✅ **No allowedAddresses needed**: Twilio handles security via their network
- ✅ **Simple format**: Just phone number and basic settings
- ✅ **Krisp enabled**: Noise cancellation for better call quality

### **Twilio SIP Configuration Steps:**
1. **Purchase Twilio phone number**: `+13074606119`
2. **Configure SIP domain** in Twilio Console
3. **Set webhook URL** to your LiveKit SIP endpoint: `sip:40.81.229.194:5060`
4. **Create trunk and dispatch** using the JSON formats above
5. **Test calls** - each creates individual room: `call-<unique-id>`

### **Expected Behavior:**
- 📞 **Incoming call** to `+13074606119`
- 🎯 **Twilio routes** to `sip:40.81.229.194:5060`
- 🏠 **LiveKit creates room**: `call-abc123def456`
- 🤖 **Agent auto-joins** room for call handling
- ✅ **Call connected** and ready for conversation

## 🔧 ENVIRONMENT VARIABLES

```bash
LIVEKIT_URL="http://localhost:7880"
LIVEKIT_API_KEY="108378f337bbab3ce4e944554bed555a"
LIVEKIT_API_SECRET="2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d"
PHONE_NUMBER="+13074606119"
EXTERNAL_IP="40.81.229.194"
```

## 📋 TROUBLESHOOTING

### **Common Twilio Issues:**
1. **Call reaches 180 Ringing but no pickup**: Trunk/dispatch not created properly
2. **Authentication errors**: Twilio doesn't use basic auth - remove credentials
3. **Network issues**: Ensure port 5060 is open on your server
4. **Agent not joining**: Check roomConfig.agents configuration

### **Verification Commands:**
```bash
# List created trunks
lk sip inbound list

# List dispatch rules  
lk sip dispatch list

# Check SIP service logs
docker logs voice-agent-sip-twilio
```