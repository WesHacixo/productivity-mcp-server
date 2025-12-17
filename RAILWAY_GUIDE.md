# Railway Deployment Guide - Complete Setup

## 🎯 Quick Answer: Where to Get Your Service URL

### Your service is currently "Unexposed"

Your Railway service shows as **"Unexposed Service"** which means it doesn't have a public URL yet. Here's how to get one:

## Step 1: Generate a Public Domain

1. **Go to your Railway project:**
   - https://railway.com/project/6e921b3a-2d3e-4aa8-af94-cfa4f48cc5a5

2. **Click on "productivity-mcp-server" service**

3. **Go to the "Settings" tab**

4. **Look for "Networking" or "Generate Domain" section**
   - If you don't see it, Railway may have moved it
   - Try looking in the main service view (not settings)

5. **Click "Generate Domain" or "Expose Service"**
   - Railway will create a public URL like: `https://productivity-mcp-server-production.up.railway.app`

### Alternative: Check Deployments Tab

1. Go to your service
2. Click **"Deployments"** tab
3. Open the latest successful deployment
4. The public URL should be shown there

## Step 2: About Webhooks

Railway webhooks are at the **project level**, not service level. They're used for:
- **GitHub integration** - Auto-deploy on push (already set up)
- **External notifications** - Get notified when deployments happen
- **CI/CD integration** - Trigger external workflows

### Where to Find Webhooks:

1. **Go to Project Settings:**
   - https://railway.com/project/6e921b3a-2d3e-4aa8-af94-cfa4f48cc5a5/settings

2. **Look for "Webhooks" section**

3. **You can create webhooks for:**
   - Deployment events (start, success, failure)
   - Service events
   - Environment events

### Webhook URL You Shared:

The URL you shared earlier:
```
https://railway.com/project/6e921b3a-2d3e-4aa8-af94-cfa4f48cc5a5/settings/webhooks/new?environmentId=494b4e30-a755-4953-9de9-3b569e038246
```

This is the **create webhook page** for your production environment. You can use this to:
- Set up notifications to Slack/Discord
- Trigger external CI/CD pipelines
- Monitor deployments

## Step 3: Once You Have the URL

### Test Your Deployment:

```bash
# Replace with your actual Railway URL
export RAILWAY_URL="https://your-service-name.up.railway.app"

# Test health
curl $RAILWAY_URL/health

# Test MCP initialize
curl -X POST $RAILWAY_URL/mcp/initialize
```

### Update Webapp Configuration:

In your webapp's Node.js server environment:

```bash
MCP_SERVER_URL=https://your-service-name.up.railway.app
```

## Troubleshooting

### If "Generate Domain" Button is Missing:

1. **Check Railway Plan:**
   - Free tier should allow public domains
   - Some features require paid plans

2. **Check Service Type:**
   - Make sure it's a "Web Service" not a "Background Worker"
   - Web services get public URLs automatically

3. **Try Railway CLI:**
   ```bash
   railway domain
   railway expose
   ```

### If Service Won't Start:

1. Check **Logs** tab in Railway dashboard
2. Verify environment variables are set:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `CLAUDE_API_KEY` (optional)
   - `PORT` (Railway sets this automatically)

## Next Steps

1. ✅ Generate public domain for your service
2. ✅ Test the health endpoint
3. ✅ Update webapp `MCP_SERVER_URL` environment variable
4. ✅ Test full integration

## Need Help?

If you can't find the "Generate Domain" button:
- Check Railway documentation: https://docs.railway.app
- Try Railway CLI: `railway domain`
- Contact Railway support
