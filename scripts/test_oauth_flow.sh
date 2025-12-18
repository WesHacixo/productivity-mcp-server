#!/bin/bash

# OAuth 2.1 E2E Test Script
# Tests the complete OAuth flow with PKCE

set -e

BASE_URL="${1:-https://productivity-mcp-server-production.up.railway.app}"
CLIENT_ID="${2:-claude-desktop}"
REDIRECT_URI="${3:-https://claude.ai/api/mcp/auth_callback}"

echo "🧪 Testing OAuth 2.1 Flow with PKCE"
echo "===================================="
echo "Base URL: $BASE_URL"
echo "Client ID: $CLIENT_ID"
echo "Redirect URI: $REDIRECT_URI"
echo ""

# Step 1: Test OAuth Discovery
echo "📋 Step 1: Testing OAuth Discovery..."
DISCOVERY_RESPONSE=$(curl -s "$BASE_URL/.well-known/oauth-authorization-server")
if echo "$DISCOVERY_RESPONSE" | grep -q "authorization_endpoint"; then
    echo "✅ OAuth discovery working"
    echo "$DISCOVERY_RESPONSE" | jq . 2>/dev/null || echo "$DISCOVERY_RESPONSE"
else
    echo "❌ OAuth discovery failed"
    echo "Response: $DISCOVERY_RESPONSE"
    exit 1
fi
echo ""

# Step 2: Generate PKCE values
echo "📋 Step 2: Generating PKCE values..."
# Generate code_verifier (43-128 chars, base64url safe)
CODE_VERIFIER=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-43)
# Generate code_challenge (SHA256 hash, base64url encoded)
CODE_CHALLENGE=$(echo -n "$CODE_VERIFIER" | openssl dgst -binary -sha256 | openssl base64 | tr -d "=+/" | cut -c1-43)
STATE=$(openssl rand -hex 16)

echo "Code Verifier: $CODE_VERIFIER"
echo "Code Challenge: $CODE_CHALLENGE"
echo "State: $STATE"
echo ""

# Step 3: Test Authorization Endpoint
echo "📋 Step 3: Testing Authorization Endpoint..."
AUTH_URL="$BASE_URL/authorize?client_id=$CLIENT_ID&redirect_uri=$(echo -n $REDIRECT_URI | jq -sRr @uri)&response_type=code&code_challenge=$CODE_CHALLENGE&code_challenge_method=S256&state=$STATE&scope=claudeai"

echo "Request URL: $AUTH_URL"
echo ""

AUTH_RESPONSE=$(curl -s -L -w "\n%{http_code}" "$AUTH_URL")
HTTP_CODE=$(echo "$AUTH_RESPONSE" | tail -n1)
BODY=$(echo "$AUTH_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Authorization endpoint working (HTTP $HTTP_CODE)"
    # Extract code from redirect
    if echo "$BODY" | grep -q "code="; then
        AUTH_CODE=$(echo "$BODY" | grep -oP 'code=\K[^&]*' | head -1)
        echo "✅ Authorization code received: ${AUTH_CODE:0:20}..."
    else
        echo "⚠️  No code in response (might be HTML redirect)"
        echo "Response: ${BODY:0:200}..."
        # Try to extract from Location header
        LOCATION=$(curl -s -I "$AUTH_URL" | grep -i "location:" | cut -d' ' -f2- | tr -d '\r')
        if [ -n "$LOCATION" ]; then
            echo "Location: $LOCATION"
            AUTH_CODE=$(echo "$LOCATION" | grep -oP 'code=\K[^&]*' | head -1)
            if [ -n "$AUTH_CODE" ]; then
                echo "✅ Authorization code from Location: ${AUTH_CODE:0:20}..."
            fi
        fi
    fi
else
    echo "❌ Authorization endpoint failed (HTTP $HTTP_CODE)"
    echo "Response: $BODY"
    exit 1
fi
echo ""

# Step 4: Test Token Exchange
if [ -z "$AUTH_CODE" ]; then
    echo "⚠️  Skipping token exchange (no auth code received)"
    echo "💡 This might be because the endpoint redirects to a login page"
    echo "💡 Try manually visiting the URL above to get the auth code"
    exit 0
fi

echo "📋 Step 4: Testing Token Exchange..."
TOKEN_RESPONSE=$(curl -s -X POST "$BASE_URL/oauth/token" \
    -H "Content-Type: application/json" \
    -d "{
        \"grant_type\": \"authorization_code\",
        \"code\": \"$AUTH_CODE\",
        \"code_verifier\": \"$CODE_VERIFIER\",
        \"redirect_uri\": \"$REDIRECT_URI\"
    }")

if echo "$TOKEN_RESPONSE" | grep -q "access_token"; then
    echo "✅ Token exchange successful!"
    echo "$TOKEN_RESPONSE" | jq . 2>/dev/null || echo "$TOKEN_RESPONSE"
    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token' 2>/dev/null || echo "")
    if [ -n "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]; then
        echo ""
        echo "✅ Access Token: ${ACCESS_TOKEN:0:30}..."
    fi
else
    echo "❌ Token exchange failed"
    echo "Response: $TOKEN_RESPONSE"
    exit 1
fi
echo ""

# Step 5: Test MCP Endpoint with Token
if [ -n "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]; then
    echo "📋 Step 5: Testing MCP Initialize with Access Token..."
    MCP_RESPONSE=$(curl -s -X POST "$BASE_URL/mcp/initialize" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{}')
    
    if echo "$MCP_RESPONSE" | grep -q "protocolVersion\|capabilities"; then
        echo "✅ MCP endpoint working with access token!"
        echo "$MCP_RESPONSE" | jq . 2>/dev/null || echo "$MCP_RESPONSE"
    else
        echo "❌ MCP endpoint failed"
        echo "Response: $MCP_RESPONSE"
    fi
fi

echo ""
echo "🎉 OAuth 2.1 E2E Test Complete!"
