# Debugging OAuth 2.1 Flow

## Current Status

The OAuth endpoints are returning **404**, which means the latest code hasn't been deployed yet.

## Quick Fix

### Step 1: Deploy Latest Code

```bash
cd /Users/damian/Projects/productivity-mcp-server
git add .
git commit -m "Fix OAuth 2.1: allow custom schemes, always store auth codes"
git push
```

**Wait 2-3 minutes** for Railway to deploy.

### Step 2: Test OAuth Discovery

```bash
curl "https://productivity-mcp-server-production.up.railway.app/.well-known/oauth-authorization-server"
```

**Expected:** JSON with `authorization_endpoint`, `token_endpoint`, etc.

### Step 3: Test Authorization Endpoint

```bash
curl -I "https://productivity-mcp-server-production.up.railway.app/authorize?client_id=claude-desktop&redirect_uri=https://claude.ai/api/mcp/auth_callback&response_type=code&code_challenge=test123&code_challenge_method=S256&state=test123&scope=claudeai"
```

**Expected:** HTTP 302 redirect to `https://claude.ai/api/mcp/auth_callback?code=...&state=test123`

### Step 4: Run E2E Test Script

```bash
./scripts/test_oauth_flow.sh
```

This will test the complete flow:
1. OAuth discovery
2. PKCE generation
3. Authorization request
4. Token exchange
5. MCP endpoint with token

## Common Issues

### Issue 1: 404 on `/authorize`

**Problem:** Code not deployed  
**Fix:** Deploy latest code (see Step 1)

### Issue 2: "redirect_uri scheme not allowed"

**Problem:** Custom scheme validation  
**Fix:** Already fixed - now allows `claude://` scheme

### Issue 3: "code_verifier does not match code_challenge"

**Problem:** PKCE validation failing  
**Fix:** Ensure:
- `code_challenge = base64url(SHA256(code_verifier))`
- Both use base64url encoding (no padding, URL-safe)

### Issue 4: "authorization code not found"

**Problem:** Auth code not stored or expired  
**Fix:** 
- Check if code was stored (now always stored)
- Check expiration (10 minutes)
- Check if code was already used (one-time use)

### Issue 5: "redirect_uri not registered"

**Problem:** Redirect URI validation  
**Fix:** Use one of these:
- `https://claude.ai/api/mcp/auth_callback`
- `https://claude.com/api/mcp/auth_callback`
- `claude://oauth-callback`
- `http://localhost` (dev)

## Manual Testing

### 1. Generate PKCE Values

```bash
# Generate code_verifier (43-128 chars)
CODE_VERIFIER=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-43)

# Generate code_challenge (SHA256 hash)
CODE_CHALLENGE=$(echo -n "$CODE_VERIFIER" | openssl dgst -binary -sha256 | openssl base64 | tr -d "=+/" | cut -c1-43)

echo "Code Verifier: $CODE_VERIFIER"
echo "Code Challenge: $CODE_CHALLENGE"
```

### 2. Request Authorization

```bash
STATE=$(openssl rand -hex 16)
AUTH_URL="https://productivity-mcp-server-production.up.railway.app/authorize?client_id=claude-desktop&redirect_uri=https://claude.ai/api/mcp/auth_callback&response_type=code&code_challenge=$CODE_CHALLENGE&code_challenge_method=S256&state=$STATE&scope=claudeai"

# Open in browser or curl
curl -L "$AUTH_URL"
```

### 3. Extract Auth Code

From the redirect URL, extract the `code` parameter.

### 4. Exchange for Token

```bash
curl -X POST https://productivity-mcp-server-production.up.railway.app/oauth/token \
  -H "Content-Type: application/json" \
  -d "{
    \"grant_type\": \"authorization_code\",
    \"code\": \"AUTH_CODE_FROM_STEP_3\",
    \"code_verifier\": \"$CODE_VERIFIER\",
    \"redirect_uri\": \"https://claude.ai/api/mcp/auth_callback\"
  }"
```

**Expected:** JSON with `access_token`, `token_type`, `expires_in`, etc.

### 5. Use Access Token

```bash
curl -X POST https://productivity-mcp-server-production.up.railway.app/mcp/initialize \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

## Debugging Tips

### Check Server Logs

Railway Dashboard → Your Service → Logs

Look for:
- OAuth authorization requests
- Token exchange requests
- PKCE validation errors
- Auth code storage/retrieval

### Test Locally

```bash
# Run server locally
cd /Users/damian/Projects/productivity-mcp-server
go run main.go

# Test against localhost
./scripts/test_oauth_flow.sh http://localhost:8080
```

### Verify Routes

```bash
# Check if routes are registered
curl http://localhost:8080/health
curl http://localhost:8080/.well-known/oauth-authorization-server
curl http://localhost:8080/authorize?client_id=test&redirect_uri=http://localhost&response_type=code&state=test
```

## What Was Fixed

1. ✅ **Custom Scheme Support** - Now allows `claude://` redirect URIs
2. ✅ **Always Store Auth Codes** - Codes are always stored (not just with PKCE)
3. ✅ **PKCE Validation** - Proper S256 validation
4. ✅ **Error Messages** - Better error descriptions

## Next Steps

1. Deploy latest code
2. Run E2E test script
3. Test with Claude Desktop
4. Check Railway logs for any errors
