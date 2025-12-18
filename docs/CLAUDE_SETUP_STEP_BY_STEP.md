# Claude Desktop Setup - Step by Step

## Quick Answer

**No, you need more than just the URL!** You need:
1. Server URL ✅
2. OAuth 2.0 configuration (Authorization URL, Token URL, Client ID, Client Secret)

## What You Need

### Server Information
- **Server URL:** `https://productivity-mcp-server-production.up.railway.app`
- **Authorization URL:** `https://productivity-mcp-server-production.up.railway.app/oauth/authorize`
- **Token URL:** `https://productivity-mcp-server-production.up.railway.app/oauth/token`

### Client Credentials (Choose One)

**Option 1: Use Default Client (Easiest - For Testing)**
- **Client ID:** `claude-desktop`
- **Client Secret:** `claude-desktop-secret-dev`

**Option 2: Register Your Own Client**
- Register via `/oauth/register` endpoint
- Get your own Client ID and Secret

## Step-by-Step Instructions

### Step 1: Deploy Latest Code (If Not Done)

The OAuth endpoints need to be deployed. If `/oauth/authorize` returns 404, deploy:

```bash
cd /Users/damian/Projects/productivity-mcp-server
git add .
git commit -m "Add OAuth client registration and Claude Desktop setup"
git push
# Wait ~2-3 minutes for Railway to deploy
```

### Step 2: Verify OAuth Endpoints Work

```bash
# Test authorization endpoint
curl "https://productivity-mcp-server-production.up.railway.app/oauth/authorize?client_id=claude-desktop&redirect_uri=http://localhost&response_type=code&state=test"

# Should redirect (not return 404)
```

### Step 3: Open Claude Desktop

1. Open **Claude Desktop** app
2. Press `Cmd+,` (or go to Settings)
3. Click **"Connectors"** tab (or "MCP Servers")

### Step 4: Add MCP Server

1. Click **"Add Connector"** or **"Add MCP Server"**
2. You'll see a form with:
   - **Server URL** (required)
   - **Authentication** (required for remote servers)

### Step 5: Fill in Server URL

```
https://productivity-mcp-server-production.up.railway.app
```

### Step 6: Select OAuth 2.0 Authentication

**Important:** For remote servers, you MUST select OAuth 2.0 (not API key or none)

### Step 7: Configure OAuth Settings

Fill in these fields:

**Authorization URL:**
```
https://productivity-mcp-server-production.up.railway.app/oauth/authorize
```

**Token URL:**
```
https://productivity-mcp-server-production.up.railway.app/oauth/token
```

**Client ID:**
```
claude-desktop
```

**Client Secret:**
```
claude-desktop-secret-dev
```

### Step 8: Save and Connect

1. Click **"Save"** or **"Connect"**
2. Claude Desktop will attempt to connect
3. You may see an OAuth authorization screen
4. Approve the connection
5. Status should show "Connected" ✅

### Step 9: Test It!

Once connected, try asking Claude:

- "Create a task to finish the report by Friday"
- "What tasks do I have?"
- "Create a goal to learn Swift by end of month"
- "Show me my goals"

## Alternative: Register Your Own Client

If you want your own client credentials:

### Register Client

```bash
curl -X POST https://productivity-mcp-server-production.up.railway.app/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "my-claude-desktop",
    "client_secret": "my-secret-key",
    "redirect_uris": ["http://localhost", "claude://oauth-callback"],
    "name": "My Claude Desktop"
  }'
```

**Response:**
```json
{
  "client_id": "my-claude-desktop",
  "client_secret": "my-secret-key",
  "redirect_uris": ["http://localhost", "claude://oauth-callback"],
  "name": "My Claude Desktop"
}
```

Then use these credentials in Claude Desktop.

## Troubleshooting

### "404 page not found" on OAuth endpoints

**Problem:** Latest code not deployed  
**Solution:** Deploy latest code (see Step 1)

### "Invalid client" Error

**Problem:** Client ID not recognized  
**Solution:** 
- Use `claude-desktop` as Client ID
- Or register your own client via `/oauth/register`

### "Invalid redirect_uri" Error

**Problem:** Redirect URI not whitelisted  
**Solution:** 
- Use `http://localhost` as redirect_uri
- Or register client with your redirect URI

### Connection Timeout

**Problem:** Server not accessible  
**Solution:** 
- Check Railway deployment status
- Verify server URL is correct
- Check Railway logs

### "Unauthorized" on MCP Endpoints

**Problem:** Missing or invalid token  
**Solution:** 
- Complete OAuth flow
- Ensure token is included in Authorization header
- Check token hasn't expired

## Quick Test Commands

```bash
# 1. Test health
curl https://productivity-mcp-server-production.up.railway.app/health

# 2. Test OAuth authorize
curl "https://productivity-mcp-server-production.up.railway.app/oauth/authorize?client_id=claude-desktop&redirect_uri=http://localhost&response_type=code&state=test"

# 3. Test MCP initialize (needs token)
curl -X POST https://productivity-mcp-server-production.up.railway.app/mcp/initialize \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

## Summary

**What you need:**
1. ✅ Server URL: `https://productivity-mcp-server-production.up.railway.app`
2. ✅ Authorization URL: `https://productivity-mcp-server-production.up.railway.app/oauth/authorize`
3. ✅ Token URL: `https://productivity-mcp-server-production.up.railway.app/oauth/token`
4. ✅ Client ID: `claude-desktop`
5. ✅ Client Secret: `claude-desktop-secret-dev`

**Time to complete:** ~5 minutes (after code is deployed)
