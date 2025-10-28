# Simple JWT token generator for LiveKit
param(
    [string]$ApiKey = "108378f337bbab3ce4e944554bed555a",
    [string]$ApiSecret = "2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d"
)

# Create JWT header
$header = @{
    "alg" = "HS256"
    "typ" = "JWT"
} | ConvertTo-Json -Compress

# Create JWT payload with long expiration
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$exp = $now + (365 * 24 * 3600) # 1 year from now

$payload = @{
    "iss" = $ApiKey
    "sub" = $ApiKey
    "aud" = "livekit"
    "exp" = $exp
    "video" = @{
        "roomCreate" = $true
        "roomList" = $true
        "room" = "*"
        "canPublish" = $true
        "canSubscribe" = $true
        "canPublishData" = $true
        "canUpdateOwnMetadata" = $true
        "sip" = @{
            "call" = $true
        }
    }
} | ConvertTo-Json -Compress

# Base64 encode (URL safe)
function ConvertTo-Base64Url {
    param([string]$text)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $base64 = [Convert]::ToBase64String($bytes)
    return $base64.Replace('+', '-').Replace('/', '_').TrimEnd('=')
}

$headerEncoded = ConvertTo-Base64Url $header
$payloadEncoded = ConvertTo-Base64Url $payload

# Create signature
$signingInput = "$headerEncoded.$payloadEncoded"
$secretBytes = [System.Text.Encoding]::UTF8.GetBytes($ApiSecret)
$signingBytes = [System.Text.Encoding]::UTF8.GetBytes($signingInput)

$hmac = New-Object System.Security.Cryptography.HMACSHA256
$hmac.Key = $secretBytes
$signatureBytes = $hmac.ComputeHash($signingBytes)
$signature = [Convert]::ToBase64String($signatureBytes).Replace('+', '-').Replace('/', '_').TrimEnd('=')

$jwt = "$headerEncoded.$payloadEncoded.$signature"
Write-Output "Bearer $jwt"