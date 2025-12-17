# Quick Start: Get Your Railway Service URL

## You've Added Railway API Key to Keychain

You ran:
```bash
security add-generic-password -a "DAE" -s "******" -w "$RAILWAY_API" -U
```

## Option 1: Use Python Script (Recommended)

The Python script will try to access the keychain automatically:

```bash
python3 scripts/get_railway_url.py
```

If keychain access requires a password prompt, you'll need to:
1. Allow the keychain access when prompted
2. Or use Option 2 below

## Option 2: Export Environment Variable

If keychain access doesn't work, export the variable:

```bash
# Get the key from keychain first
export RAILWAY_API=$(security find-generic-password -a "DAE" -w)

# Then run the script
python3 scripts/get_railway_url.py
```

## Option 3: Pass Token Directly

```bash
python3 scripts/get_railway_url.py 'your-railway-api-token-here'
```

## What You'll Get

The script will show:
- All services in your Railway project
- Their public domains (if exposed)
- Your MCP server URL (if it has a domain)
- Instructions to test and configure

## If Service Has No Domain

If you see "No domain (unexposed)", you need to:

1. Go to Railway dashboard
2. Click on "productivity-mcp-server" service  
3. Look for "Generate Domain" or "Expose Service" button
4. Click it to create a public URL

## Next Steps After Getting URL

1. **Test the deployment:**
   ```bash
   curl https://your-service.up.railway.app/health
   ```

2. **Update webapp:**
   ```bash
   # In productivity_tool_app/.env or server environment
   MCP_SERVER_URL=https://your-service.up.railway.app
   ```

3. **Test MCP endpoints:**
   ```bash
   curl -X POST https://your-service.up.railway.app/mcp/initialize
   ```
