# Using Railway API to Get Service URL

You've added the Railway API key to OS secrets. Here's how to use it programmatically.

## Quick Start

### Option 1: Set Environment Variable

```bash
# Get your API token from: https://railway.com/account/tokens
export RAILWAY_API='your-token-here'

# Then run the script
python3 scripts/get_railway_url.py
```

### Option 2: Pass as Argument

```bash
python3 scripts/get_railway_url.py 'your-token-here'
```

### Option 3: Add to macOS Keychain

```bash
# Add to keychain
security add-generic-password -s "RAILWAY_API" -w "your-token-here" -a "$USER"

# Script will automatically find it
python3 scripts/get_railway_url.py
```

## What the Script Does

1. **Fetches service information** from Railway GraphQL API
2. **Lists all services** and their domains
3. **Shows your MCP server URL** if it has a public domain
4. **Provides instructions** if the service is unexposed

## Example Output

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

## Getting Your API Token

1. Go to: https://railway.com/account/tokens
2. Click "New Token"
3. Give it a name (e.g., "MCP Server Access")
4. Copy the token (you won't see it again!)

## Troubleshooting

### "API key not found"
- Make sure you've exported the variable: `export RAILWAY_API='token'`
- Or pass it as argument: `python3 scripts/get_railway_url.py YOUR_TOKEN`

### "No services found"
- Check that the PROJECT_ID in the script matches your Railway project
- Verify your API token has access to the project

### "Service has no public domain"
- Your service is "unexposed"
- Go to Railway dashboard and click "Generate Domain" for the service

## Next Steps

Once you have the URL:

1. **Test the deployment:**
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
