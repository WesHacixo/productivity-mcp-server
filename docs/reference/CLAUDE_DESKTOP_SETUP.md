# Claude Desktop MCP Server Configuration

## Your MCP Server URL

Based on your Railway deployment, your MCP server is at:

```
https://productivity-mcp-server-production.up.railway.app
```

## Current Implementation: HTTP POST (✅ Correct!)

**Good news:** Your server uses **HTTP POST with JSON responses** - this is the **recommended approach** per Anthropic's current standard.

**According to Anthropic's official documentation:**
- ✅ **Streamable HTTP** is the recommended transport for remote MCP servers
- ⚠️ **SSE is being deprecated** (don't use it)
- ✅ Your HTTP POST implementation matches "Streamable HTTP"
- ✅ Future-proof and standard-compliant

**Current endpoints:**
- `POST /mcp/initialize` - Initialize MCP connection
- `POST /mcp/list_tools` - List available tools  
- `POST /mcp/call_tool` - Call a tool

## Claude Desktop Configuration

### Option 1: Remote Server with OAuth (Required)

For your deployed Railway server, **OAuth 2.0 authentication is required**:

1. Open Claude Desktop
2. Go to **Settings > Connectors**
3. Click **"Add Connector"** or **"Add MCP Server"**
4. Enter your server URL: `https://productivity-mcp-server-production.up.railway.app`
5. **Select OAuth 2.0 authentication**
6. Configure OAuth:
   - **Authorization URL:** `https://productivity-mcp-server-production.up.railway.app/oauth/authorize`
   - **Token URL:** `https://productivity-mcp-server-production.up.railway.app/oauth/token`
   - **Client ID:** (register your server - see MCP_OAUTH_SETUP.md)
   - **Client Secret:** (from registration)

**Note:** OAuth endpoints are now implemented. You need to:
1. Register your MCP server as an OAuth client
2. Complete the OAuth flow implementation (see MCP_OAUTH_SETUP.md)

**Important:** 
- ⚠️ Remote servers **cannot** be configured via `claude_desktop_config.json`
- ✅ Must use the Settings > Connectors UI
- ✅ Your HTTP POST endpoints work perfectly with this

### Option 2: Local stdio (For Local Development)

If you want to run the server locally, use stdio:

**MCP Endpoints:**
- Initialize: `POST https://productivity-mcp-server-production.up.railway.app/mcp/initialize`
- List Tools: `POST https://productivity-mcp-server-production.up.railway.app/mcp/list_tools`
- Call Tool: `POST https://productivity-mcp-server-production.up.railway.app/mcp/call_tool`

Open Claude Desktop → Settings → Developer → Edit Config

Add this to your `claude_desktop_config.json`:

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

**Or if you have a compiled binary:**

```json
{
  "mcpServers": {
    "productivity": {
      "command": "/Users/damian/Projects/productivity-mcp-server/server",
      "env": {
        "SUPABASE_URL": "https://your-project.supabase.co",
        "SUPABASE_ANON_KEY": "your-anon-key",
        "CLAUDE_API_KEY": "your-claude-key"
      }
    }
  }
}
```

### Option 2: HTTP Transport (If Claude Desktop Supports It)

If Claude Desktop supports HTTP POST for MCP (check their docs), you could use:

```json
{
  "mcpServers": {
    "productivity": {
      "url": "https://productivity-mcp-server-production.up.railway.app",
      "transport": "http"
    }
  }
}
```

**Note:** This depends on Claude Desktop supporting HTTP POST transport. stdio (Option 1) is more reliable.

## Test Your Server

First, verify your server is running:

```bash
curl https://productivity-mcp-server-production.up.railway.app/health
```

Should return:
```json
{"status":"ok","service":"productivity-mcp-server"}
```

Then test MCP initialize:

```bash
curl -X POST https://productivity-mcp-server-production.up.railway.app/mcp/initialize
```

Should return:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocolVersion": "2024-11-05",
    "capabilities": {
      "logging": {},
      "tools": {}
    },
    "serverInfo": {
      "name": "Productivity MCP Server",
      "version": "1.0.0"
    }
  }
}
```

## Important Notes

✅ **Your server uses standard HTTP POST** - clean, maintainable, no SSE complexity.

✅ **Recommended approach:** Use **stdio transport** (Option 1) - Claude Desktop runs your server locally as a subprocess. This is:
- Standard MCP protocol
- No network complexity
- Works offline
- Clean code quality
- No SSE needed

## Quick Test

To see if your server is accessible:

```bash
# Health check
curl https://productivity-mcp-server-production.up.railway.app/health

# MCP initialize
curl -X POST https://productivity-mcp-server-production.up.railway.app/mcp/initialize \
  -H "Content-Type: application/json"
```

If both work, your server is running correctly. The Claude Desktop connection may need SSE support added to the server.
