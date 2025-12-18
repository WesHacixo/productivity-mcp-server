# Claude Desktop Setup - Simple Guide

## Quick Answer

**No, you don't just add the URL!** Claude Desktop requires OAuth 2.0 authentication for remote MCP servers.

## What You Need

1. **Server URL:** `https://productivity-mcp-server-production.up.railway.app`
2. **OAuth Configuration:**
   - Authorization URL: `https://productivity-mcp-server-production.up.railway.app/oauth/authorize`
   - Token URL: `https://productivity-mcp-server-production.up.railway.app/oauth/token`
   - Client ID: (see below)
   - Client Secret: (see below)

## Step-by-Step Setup

### Step 1: Open Claude Desktop

1. Open **Claude Desktop** app
2. Go to **Settings** (gear icon or `Cmd+,`)
3. Click **"Connectors"** tab

### Step 2: Add MCP Server

1. Click **"Add Connector"** or **"Add MCP Server"**
2. You'll see options for:
   - **Server URL** (required)
   - **Authentication** (required for remote servers)

### Step 3: Enter Server URL

```
https://productivity-mcp-server-production.up.railway.app
```

### Step 4: Configure OAuth

**For remote servers, Claude Desktop requires OAuth 2.0:**

1. **Select "OAuth 2.0"** as authentication method
2. **Authorization URL:**
   ```
   https://productivity-mcp-server-production.up.railway.app/oauth/authorize
   ```
3. **Token URL:**
   ```
   https://productivity-mcp-server-production.up.railway.app/oauth/token
   ```
4. **Client ID:** (see options below)
5. **Client Secret:** (from registration)

## Client ID Options

### Option 1: Use Default/Development Client (Easiest)

For testing, you can use a default client ID. Check if your server accepts:
- **Client ID:** `mcp_client` or `claude-desktop`
- **Client Secret:** (may not be required for development)

**Test it:**
```bash
curl "https://productivity-mcp-server-production.up.railway.app/oauth/authorize?client_id=mcp_client&redirect_uri=https://example.com&response_type=code&state=test"
```

### Option 2: Register OAuth Client

If default doesn't work, you need to register:

1. **Check if registration endpoint exists:**
   ```bash
   curl -X POST https://productivity-mcp-server-production.up.railway.app/oauth/register
   ```

2. **Or manually create client:**
   - See `docs/reference/MCP_OAUTH_SETUP.md` for details
   - May require database setup for client storage

### Option 3: Temporary Workaround

For initial testing, you might be able to:
1. Use the server URL without OAuth (if Claude Desktop allows)
2. Or use local stdio mode (see below)

## Alternative: Local Development Mode

If OAuth setup is complex, you can test locally first:

### Local stdio Configuration

1. In Claude Desktop, go to **Settings → Developer → Edit Config**
2. Add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "productivity": {
      "command": "go",
      "args": ["run", "/Users/damian/Projects/productivity-mcp-server/main.go"],
      "env": {
        "SUPABASE_URL": "https://your-project.supabase.co",
        "SUPABASE_ANON_KEY": "your-anon-key",
        "CLAUDE_API_KEY": "your-claude-key",
        "PORT": "8080"
      }
    }
  }
}
```

**Note:** This only works for local development. Remote servers MUST use OAuth.

## Testing the Connection

### Test OAuth Endpoints

```bash
# Test authorization endpoint
curl "https://productivity-mcp-server-production.up.railway.app/oauth/authorize?client_id=test&redirect_uri=https://example.com&response_type=code&state=test123"

# Test token endpoint (after getting code)
curl -X POST https://productivity-mcp-server-production.up.railway.app/oauth/token \
  -H "Content-Type: application/json" \
  -d '{"grant_type":"authorization_code","code":"test_code","client_id":"test"}'
```

### Test MCP Endpoints

```bash
# Test initialize (needs auth token)
curl -X POST https://productivity-mcp-server-production.up.railway.app/mcp/initialize \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'

# Test list tools (needs auth token)
curl -X POST https://productivity-mcp-server-production.up.railway.app/mcp/list_tools \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

## Common Issues

### "Invalid client" Error
- Client ID not registered
- Solution: Register client or use default

### "Invalid redirect_uri" Error
- Redirect URI not whitelisted
- Solution: Check OAuth server configuration

### "Unauthorized" Error
- Missing or invalid token
- Solution: Complete OAuth flow

### Connection Timeout
- Server not accessible
- Solution: Check Railway deployment status

## Next Steps After Setup

1. ✅ Claude Desktop connected
2. Test: "Create a task to finish the report by Friday"
3. Verify task appears in your app
4. Test: "What tasks do I have?"
5. Test: "Create a goal to learn Swift"

## Full Documentation

- `docs/CLAUDE_DESKTOP_QUICK_START.md` - Complete setup guide
- `docs/reference/MCP_OAUTH_SETUP.md` - OAuth configuration details
- `docs/reference/CLAUDE_DESKTOP_SETUP.md` - Full reference
