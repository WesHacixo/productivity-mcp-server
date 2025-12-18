# Claude Desktop Setup - Actual UI Guide 🎯

## What Claude Desktop Actually Shows

Based on the actual Claude Desktop UI, you only need to fill in:

1. **Connector Name** (e.g., "Productivity MCP")
2. **Remote MCP Server URL** (your server URL)
3. **OAuth Client ID** (optional - in Advanced Settings)
4. **OAuth Client Secret** (optional - in Advanced Settings)

**That's it!** Claude Desktop will auto-discover the OAuth endpoints.

## Quick Setup (2 Minutes)

### Step 1: Fill in the Form

1. **Connector Name:**
   ```
   Productivity MCP
   ```

2. **Remote MCP Server URL:**
   ```
   https://productivity-mcp-server-production.up.railway.app
   ```

3. **Advanced Settings** (click to expand):
   - **OAuth Client ID (optional):**
     ```
     claude-desktop
     ```
   - **OAuth Client Secret (optional):**
     ```
     claude-desktop-secret-dev
     ```

### Step 2: Click "Add"

Claude Desktop will:
1. ✅ Auto-discover OAuth endpoints from `/.well-known/oauth-authorization-server`
2. ✅ Use the Client ID/Secret if provided (or skip if not)
3. ✅ Connect to your MCP server

## How It Works

### OAuth Auto-Discovery

Claude Desktop automatically calls:
```
GET https://productivity-mcp-server-production.up.railway.app/.well-known/oauth-authorization-server
```

This returns:
```json
{
  "issuer": "https://productivity-mcp-server-production.up.railway.app",
  "authorization_endpoint": "https://productivity-mcp-server-production.up.railway.app/oauth/authorize",
  "token_endpoint": "https://productivity-mcp-server-production.up.railway.app/oauth/token",
  "code_challenge_methods_supported": ["S256"],
  "grant_types_supported": ["authorization_code", "refresh_token"]
}
```

Claude Desktop uses this to configure OAuth automatically! 🎉

## OAuth Client ID/Secret

### Option 1: Use Default (Easiest)

**Client ID:** `claude-desktop`  
**Client Secret:** `claude-desktop-secret-dev`

These are pre-configured in the server for easy testing.

### Option 2: Leave Empty (If Server Allows)

Some servers allow OAuth without client credentials. Try leaving them empty first!

### Option 3: Register Your Own

If you want custom credentials:

```bash
curl -X POST https://productivity-mcp-server-production.up.railway.app/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "my-claude-desktop",
    "client_secret": "my-secret",
    "redirect_uris": ["https://claude.ai/api/mcp/auth_callback", "claude://oauth-callback"],
    "name": "My Claude Desktop"
  }'
```

Then use those credentials in Claude Desktop.

## Testing

After clicking "Add":

1. Claude Desktop will attempt to connect
2. You may see an OAuth authorization screen
3. Approve the connection
4. Status should show "Connected" ✅

Then try:
- "Create a task to finish the report by Friday"
- "What tasks do I have?"

## Troubleshooting

### "Failed to discover OAuth endpoints"

**Problem:** Discovery endpoint not found  
**Solution:** Make sure latest code is deployed with `/.well-known/oauth-authorization-server` endpoint

### "Invalid client"

**Problem:** Client ID not recognized  
**Solution:** Use `claude-desktop` as Client ID, or register your own

### "Connection failed"

**Problem:** Server not accessible  
**Solution:** 
- Check Railway deployment status
- Verify server URL is correct
- Test: `curl https://productivity-mcp-server-production.up.railway.app/health`

## Summary

**What you actually need:**
1. ✅ Connector Name: `Productivity MCP`
2. ✅ Server URL: `https://productivity-mcp-server-production.up.railway.app`
3. ✅ (Optional) Client ID: `claude-desktop`
4. ✅ (Optional) Client Secret: `claude-desktop-secret-dev`

**Claude Desktop handles the rest automatically!** 🚀
