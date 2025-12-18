# Final Deployment Checklist - OAuth 2.1 Production Ready 🚀

## Pre-Deployment Verification

### ✅ Code Status
- [x] OAuth 2.1 with PKCE fully implemented
- [x] Error redirects per OAuth 2.1 spec
- [x] Custom scheme support (`claude://`)
- [x] Claude redirect URIs configured
- [x] Debug instrumentation added (will be removed after verification)
- [x] Build successful

### ✅ Features Implemented
- [x] `/authorize` and `/oauth/authorize` routes
- [x] `/.well-known/oauth-authorization-server` discovery
- [x] `/oauth/token` with PKCE validation
- [x] `/oauth/introspect` for token validation
- [x] `/oauth/register` for client registration
- [x] Default clients: `claude-desktop`, `mcp_client`
- [x] Auth code storage with expiration
- [x] One-time use codes
- [x] PKCE S256 validation

## Deployment Steps

### Step 1: Final Code Review

```bash
cd /Users/damian/Projects/productivity-mcp-server

# Verify build
go build .

# Check what will be committed
git status
```

### Step 2: Commit All Changes

```bash
git add .
git commit -m "feat: OAuth 2.1 implementation with PKCE, error redirects, and Claude Desktop support

- Implement OAuth 2.1 authorization code flow with PKCE (S256)
- Add /authorize and /oauth/authorize endpoints
- Add OAuth discovery endpoint (/.well-known/oauth-authorization-server)
- Support Claude redirect URIs (claude.ai/api/mcp/auth_callback, claude://oauth-callback)
- Implement proper error redirects per OAuth 2.1 spec
- Add default OAuth clients (claude-desktop, mcp_client)
- Add auth code storage with expiration and one-time use
- Add debug instrumentation for troubleshooting
- Support custom URL schemes for native app redirects"
```

### Step 3: Push to Railway

```bash
git push origin master
# or
git push origin main
```

**Railway will automatically:**
1. Detect the push
2. Build the Go binary
3. Deploy to production
4. Run health checks

**Wait 2-3 minutes** for deployment to complete.

### Step 4: Verify Deployment

```bash
# Test OAuth discovery
curl "https://productivity-mcp-server-production.up.railway.app/.well-known/oauth-authorization-server"

# Should return JSON with authorization_endpoint, token_endpoint, etc.

# Test authorization endpoint
curl -I "https://productivity-mcp-server-production.up.railway.app/authorize?client_id=claude-desktop&redirect_uri=https://claude.ai/api/mcp/auth_callback&response_type=code&code_challenge=test123&code_challenge_method=S256&state=test123&scope=claudeai"

# Should return HTTP 302 redirect (not 404)
```

### Step 5: Test in Claude Desktop

1. Open **Claude Desktop**
2. Go to **Settings → Connectors**
3. Click **"Add custom connector"**
4. Enter:
   - **Connector Name:** `Productivity MCP`
   - **Remote MCP Server URL:** `https://productivity-mcp-server-production.up.railway.app`
   - **Advanced Settings:**
     - **OAuth Client ID:** `claude-desktop` (optional)
     - **OAuth Client Secret:** `claude-desktop-secret-dev` (optional)
5. Click **"Add"**
6. Claude Desktop should:
   - Auto-discover OAuth endpoints
   - Initiate OAuth flow
   - Redirect to authorization
   - Complete token exchange
   - Show "Connected" status

### Step 6: Verify OAuth Flow

After connection, test MCP tools:

- "Create a task to finish the report by Friday"
- "What tasks do I have?"
- "Create a goal to learn Swift by end of month"

## Environment Variables (Railway)

Ensure these are set in Railway Dashboard:

**Required:**
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anon key

**Optional but Recommended:**
- `JWT_SECRET` - Generate with: `openssl rand -base64 32`
- `CLAUDE_API_KEY` - For AI features
- `LOG_LEVEL` - Set to `INFO` or `DEBUG`
- `GIN_MODE` - Set to `release` for production

**Auto-set by Railway:**
- `PORT` - Automatically set

## Post-Deployment Verification

### Health Checks

```bash
# Basic health
curl https://productivity-mcp-server-production.up.railway.app/health

# Readiness check
curl https://productivity-mcp-server-production.up.railway.app/ready
```

### OAuth Endpoints

```bash
# Discovery
curl https://productivity-mcp-server-production.up.railway.app/.well-known/oauth-authorization-server

# Authorization (should redirect)
curl -L "https://productivity-mcp-server-production.up.railway.app/authorize?client_id=claude-desktop&redirect_uri=https://claude.ai/api/mcp/auth_callback&response_type=code&code_challenge=test123&code_challenge_method=S256&state=test123&scope=claudeai"
```

### MCP Endpoints (Require Auth)

```bash
# This should fail with 401 (needs token)
curl -X POST https://productivity-mcp-server-production.up.railway.app/mcp/initialize \
  -H "Content-Type: application/json" \
  -d '{}'
```

## Troubleshooting

### If OAuth Discovery Returns 404

**Problem:** Latest code not deployed  
**Solution:** Wait a few more minutes, check Railway deployment logs

### If Authorization Returns 404

**Problem:** Routes not registered  
**Solution:** Verify `main.go` has both `/authorize` and `/oauth/authorize` routes

### If Claude Desktop Can't Connect

**Check:**
1. OAuth discovery endpoint works
2. Authorization endpoint redirects (not 404)
3. Redirect URIs are correct in client config
4. Railway logs for errors

### If PKCE Validation Fails

**Check:**
1. Code challenge is 43-128 characters for S256
2. Code verifier matches challenge (SHA256 hash)
3. Both use base64url encoding

## Cleanup (After Verification)

Once OAuth flow is confirmed working:

1. Remove debug instrumentation (optional - can keep for monitoring)
2. Review Railway logs for any errors
3. Monitor Railway metrics for performance

## Summary

**What's Being Deployed:**
- ✅ OAuth 2.1 with PKCE
- ✅ Proper error redirects
- ✅ Claude Desktop support
- ✅ OAuth discovery
- ✅ Default clients configured
- ✅ Security best practices

**Expected Result:**
- Claude Desktop can connect via OAuth 2.1
- OAuth flow completes successfully
- MCP tools work after authentication
- Errors handled per OAuth 2.1 spec

**Ready to deploy!** 🚀
