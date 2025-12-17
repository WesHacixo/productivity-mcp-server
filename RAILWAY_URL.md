# Railway Deployment URL

## ⚠️ Important: Your Service is Currently "Unexposed"

Your Railway service shows as **"Unexposed Service"** which means it doesn't have a public URL yet. You need to generate one first.

## Finding Your Railway Service URL

Your Go MCP server is deployed on Railway. To get the public URL:

### Method 1: Generate Domain (If Not Exposed)

1. Navigate to: https://railway.com/project/6e921b3a-2d3e-4aa8-af94-cfa4f48cc5a5
2. Click on **"productivity-mcp-server"** service
3. Look for **"Generate Domain"** or **"Expose Service"** button
   - This might be in the main service view or Settings tab
   - Railway automatically generates: `https://productivity-mcp-server-production.up.railway.app`
4. Once generated, copy the public URL

### Method 2: Railway Dashboard (If Already Exposed)

1. Navigate to: https://railway.com/project/6e921b3a-2d3e-4aa8-af94-cfa4f48cc5a5
2. Click on **"productivity-mcp-server"** service
3. Go to **"Settings"** tab
4. Scroll to **"Networking"** or **"Domains"** section
5. Copy the public URL (format: `https://*.up.railway.app`)

### Method 2: Railway CLI

If you have Railway CLI installed:

```bash
railway status
```

This will show the service URL.

### Method 3: Check Deployment Logs

1. Go to Railway Dashboard → Your Service
2. Click on **"Deployments"** tab
3. Open the latest deployment
4. The URL is shown in the deployment details

## Testing Your Deployment

Once you have the URL, test it:

```bash
# Replace YOUR_URL with your actual Railway URL
export RAILWAY_URL="https://your-service-name.up.railway.app"

# Test health endpoint
curl $RAILWAY_URL/health

# Expected response:
# {"status":"ok","service":"productivity-mcp-server"}

# Test MCP initialize
curl -X POST $RAILWAY_URL/mcp/initialize

# Test MCP list tools
curl -X POST $RAILWAY_URL/mcp/list_tools
```

## Updating Webapp Configuration

Once you have the Railway URL, update your webapp's Node.js server:

**In `productivity_tool_app/.env` or Railway environment:**
```bash
MCP_SERVER_URL=https://your-service-name.up.railway.app
```

**Or if using Railway for webapp too:**
- Add `MCP_SERVER_URL` as an environment variable in your webapp service
- Point it to your Go MCP server's Railway URL

## Quick Test Script

Use the provided script to test your deployment:

```bash
./scripts/find_railway_url.sh https://your-service-name.up.railway.app
```

This will test both the health endpoint and MCP initialize endpoint.

## About Webhooks

Railway webhooks are configured at the **project level**, not service level. They're useful for:
- **GitHub integration** - Auto-deploy on push (already configured)
- **External notifications** - Get alerts when deployments happen
- **CI/CD integration** - Trigger external workflows

### Webhook Configuration:

Your webhook URL:
```
https://railway.com/project/6e921b3a-2d3e-4aa8-af94-cfa4f48cc5a5/settings/webhooks/new?environmentId=494b4e30-a755-4953-9de9-3b569e038246
```

This is for your **production environment**. You can:
1. Create webhooks for deployment events
2. Set up notifications (Slack, Discord, etc.)
3. Integrate with external monitoring tools

**Note:** Webhooks are separate from your service URL. You still need to generate a public domain for your service to be accessible.
