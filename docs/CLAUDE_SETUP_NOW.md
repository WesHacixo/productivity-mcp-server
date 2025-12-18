# Claude Desktop Setup - Do This Now! 🚀

## Quick Answer

**No, you need more than just the URL!** Here's exactly what to do:

## What You Need (Copy-Paste Ready)

### For Claude Desktop Configuration:

1. **Server URL:**
   ```
   https://productivity-mcp-server-production.up.railway.app
   ```

2. **Authentication:** OAuth 2.0

3. **Authorization URL:**
   ```
   https://productivity-mcp-server-production.up.railway.app/oauth/authorize
   ```

4. **Token URL:**
   ```
   https://productivity-mcp-server-production.up.railway.app/oauth/token
   ```

5. **Client ID:**
   ```
   claude-desktop
   ```

6. **Client Secret:**
   ```
   claude-desktop-secret-dev
   ```

## Step-by-Step (5 Minutes)

### Step 1: Deploy Latest Code (2 minutes)

The OAuth endpoints need the latest code. Deploy now:

```bash
cd /Users/damian/Projects/productivity-mcp-server
git add .
git commit -m "Add OAuth client registration and production improvements"
git push
```

**Wait 2-3 minutes** for Railway to deploy.

### Step 2: Verify OAuth Works (30 seconds)

```bash
curl "https://productivity-mcp-server-production.up.railway.app/oauth/authorize?client_id=claude-desktop&redirect_uri=http://localhost&response_type=code&state=test"
```

**Should redirect** (not return 404). If 404, wait a bit longer for deployment.

### Step 3: Open Claude Desktop (1 minute)

1. Open **Claude Desktop**
2. `Cmd+,` → **Settings**
3. Click **"Connectors"** tab
4. Click **"Add Connector"**

### Step 4: Fill in the Form (1 minute)

**Server URL:**
```
https://productivity-mcp-server-production.up.railway.app
```

**Authentication:** Select **"OAuth 2.0"**

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

### Step 5: Save and Test (30 seconds)

1. Click **"Save"** or **"Connect"**
2. Claude Desktop will connect
3. Status should show **"Connected"** ✅

### Step 6: Try It! (30 seconds)

Ask Claude:
- "Create a task to finish the report by Friday"
- "What tasks do I have?"

## That's It! 🎉

You're done. Claude Desktop is now connected to your MCP server.

## Troubleshooting

### OAuth Endpoints Return 404

**Fix:** Deploy latest code (Step 1 above)

### "Invalid client" Error

**Fix:** Make sure Client ID is exactly: `claude-desktop`

### "Invalid redirect_uri" Error

**Fix:** The default client accepts:
- `http://localhost`
- `claude://oauth-callback`
- `https://claude.ai`

### Still Having Issues?

1. Check Railway logs: Railway Dashboard → Your Service → Logs
2. Test endpoints manually (see commands above)
3. Verify code is deployed (check `/health` endpoint)

## What I Just Added

✅ Default OAuth clients (`claude-desktop` and `mcp_client`)  
✅ Client registration endpoint (`/oauth/register`)  
✅ Client validation in OAuth flow  
✅ Redirect URI validation  

**You can now use Claude Desktop with the credentials above!**
