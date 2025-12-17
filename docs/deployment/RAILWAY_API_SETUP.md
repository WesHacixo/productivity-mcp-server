# Railway API Key Setup

## Current Situation

You've added the Railway API key to macOS Keychain with:
```bash
security add-generic-password -a "DAE" -s "******" -w "$RAILWAY_API" -U
```

However, the keychain retrieval is not working automatically (likely requires user interaction or the value wasn't stored).

## Quick Solutions

### Solution 1: Export in Current Session (Easiest)

```bash
# Get your Railway API token from: https://railway.com/account/tokens
export RAILWAY_API='your-token-here'

# Then run the script
python3 scripts/get_railway_url.py
```

### Solution 2: Pass Token as Argument

```bash
python3 scripts/get_railway_url.py 'your-token-here'
```

### Solution 3: Add to Shell Profile (Persistent)

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
export RAILWAY_API='your-token-here'
```

Then:
```bash
source ~/.zshrc  # or ~/.bashrc
python3 scripts/get_railway_url.py
```

## Getting Your Railway API Token

1. Go to: https://railway.com/account/tokens
2. Click "New Token"
3. Give it a name (e.g., "MCP Server Access")
4. Copy the token immediately (you won't see it again!)

## What the Script Does

Once you have the API key set, the script will:

1. ✅ Query Railway GraphQL API
2. ✅ List all services in your project
3. ✅ Show public domains for each service
4. ✅ Display your MCP server URL (if it has a domain)
5. ✅ Provide test commands and configuration instructions

## Expected Output

```
✅ Using RAILWAY_API from environment
🔍 Fetching Railway service information...

📋 Services:

  productivity-mcp-server: https://productivity-mcp-server-production.up.railway.app

✅ Your MCP Server URL:
   https://productivity-mcp-server-production.up.railway.app

Test it:
   curl https://productivity-mcp-server-production.up.railway.app/health

Update webapp:
   export MCP_SERVER_URL=https://productivity-mcp-server-production.up.railway.app
```

## If Service is Unexposed

If you see "No domain (unexposed)", you need to generate a public domain:

1. Go to: https://railway.com/project/6e921b3a-2d3e-4aa8-af94-cfa4f48cc5a5
2. Click on "productivity-mcp-server" service
3. Look for "Generate Domain" or "Expose Service" button
4. Click it to create a public URL

## Next Steps

Once you have the URL:

1. **Test deployment:**
   ```bash
   curl https://your-service.up.railway.app/health
   ```

2. **Update webapp configuration:**
   ```bash
   # In productivity_tool_app/.env or server environment
   MCP_SERVER_URL=https://your-service.up.railway.app
   ```

3. **Test MCP endpoints:**
   ```bash
   curl -X POST https://your-service.up.railway.app/mcp/initialize
   ```
