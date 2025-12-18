# Claude Desktop Quick Start Guide

## ✅ Railway Server Status

Your MCP server is **live and working** at:
```
https://productivity-mcp-server-production.up.railway.app
```

**Verified:**
- ✅ Health endpoint: `/health`
- ✅ MCP Initialize: `/mcp/initialize`
- ✅ MCP List Tools: `/mcp/list_tools`
- ✅ OAuth endpoints: `/oauth/authorize`, `/oauth/token`

## 🚀 Connect Claude Desktop

### Step 1: Open Claude Desktop Settings

1. Open **Claude Desktop** app
2. Go to **Settings** (gear icon or Cmd+,)
3. Click **"Connectors"** or **"MCP Servers"** tab

### Step 2: Add Your MCP Server

1. Click **"Add Connector"** or **"Add MCP Server"**
2. Enter your server URL:
   ```
   https://productivity-mcp-server-production.up.railway.app
   ```
3. **Select OAuth 2.0** authentication method

### Step 3: Configure OAuth

Fill in the OAuth settings:

- **Authorization URL:**
  ```
  https://productivity-mcp-server-production.up.railway.app/oauth/authorize
  ```

- **Token URL:**
  ```
  https://productivity-mcp-server-production.up.railway.app/oauth/token
  ```

- **Client ID:** (You'll need to register - see below)
- **Client Secret:** (From registration)

### Step 4: Register OAuth Client (If Needed)

If you need to register an OAuth client:

1. **Option A: Use Default Client**
   - For development, you can use a default client ID
   - Contact your server admin or check `docs/reference/MCP_OAUTH_SETUP.md`

2. **Option B: Self-Registration**
   - Some MCP servers allow self-registration
   - Check if `/oauth/register` endpoint exists

3. **Option C: Manual Registration**
   - See `docs/reference/MCP_OAUTH_SETUP.md` for manual setup

### Step 5: Test Connection

Once configured:

1. Claude Desktop will attempt to connect
2. You may see an OAuth authorization screen
3. Approve the connection
4. Claude Desktop should show "Connected" status

### Step 6: Use the Tools

Once connected, you can ask Claude:

- "Create a task to finish the report by Friday"
- "What tasks do I have?"
- "Create a goal to learn Swift by end of month"
- "Show me my goals"

Claude will use the MCP tools to interact with your productivity app!

## 🔧 Troubleshooting

### Connection Fails

1. **Check Railway Status:**
   ```bash
   curl https://productivity-mcp-server-production.up.railway.app/health
   ```
   Should return: `{"status":"ok","service":"productivity-mcp-server"}`

2. **Check OAuth Endpoints:**
   ```bash
   curl "https://productivity-mcp-server-production.up.railway.app/oauth/authorize?client_id=test&redirect_uri=https://example.com&response_type=code&state=test"
   ```
   Should redirect (even if it fails validation)

3. **Check MCP Endpoints:**
   ```bash
   curl -X POST https://productivity-mcp-server-production.up.railway.app/mcp/initialize
   ```
   Should return MCP protocol response

### OAuth Errors

- **"Invalid client"** - Client ID/Secret incorrect
- **"Invalid redirect_uri"** - Redirect URI not registered
- **"Invalid grant"** - Authorization code expired or used

### Tools Not Available

- Check that `/mcp/list_tools` returns tools
- Verify authentication token is valid
- Check Railway logs for errors

## 📝 Alternative: Local Development

If you want to test locally first:

1. **Run server locally:**
   ```bash
   cd /Users/damian/Projects/productivity-mcp-server
   go run main.go
   ```

2. **Configure Claude Desktop for local:**
   - Use `http://localhost:8080` as server URL
   - Or use stdio transport (see `docs/reference/CLAUDE_DESKTOP_SETUP.md`)

## 🎯 Next Steps

Once connected:
1. ✅ Test creating a task via Claude
2. ✅ Test creating a goal via Claude
3. ✅ Verify tasks appear in your app
4. ✅ Test natural language parsing

## 📚 Full Documentation

- `docs/reference/CLAUDE_DESKTOP_SETUP.md` - Complete setup guide
- `docs/reference/MCP_OAUTH_SETUP.md` - OAuth configuration details
- `docs/reference/MCP_TRANSPORT_STANDARD.md` - Transport protocol info
