# Railway Deployment Status

## Service URL
**MCP Server URL:** `https://productivity-mcp-server-production.up.railway.app`

## Current Status: ⚠️ 502 Error

The service is returning a 502 error, which means the application isn't responding. This could be due to:

1. **Port Configuration Issue** - Fixed in Dockerfile (was 8000, now 8080)
2. **Missing Environment Variables** - Check Railway dashboard
3. **Service Not Starting** - Check Railway logs

## Required Environment Variables

Make sure these are set in Railway:

```bash
PORT=8080                    # Railway usually sets this automatically
SUPABASE_URL=your-url        # Required
SUPABASE_ANON_KEY=your-key   # Required
CLAUDE_API_KEY=your-key      # Optional (for AI features)
```

## Next Steps

1. **Check Railway Logs:**
   ```bash
   railway logs
   ```
   Or in Railway dashboard → Your Service → Deployments → Latest → Logs

2. **Verify Environment Variables:**
   - Go to Railway Dashboard → Your Service → Variables
   - Ensure `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set

3. **Redeploy if needed:**
   - Railway should auto-deploy on git push
   - Or trigger manual deploy from dashboard

4. **Test Once Fixed:**
   ```bash
   ./scripts/test_mcp_integration.sh https://productivity-mcp-server-production.up.railway.app
   ```

## Webapp Configuration

Once the service is working, update your webapp:

**In `productivity_tool_app/.env`:**
```bash
MCP_SERVER_URL=https://productivity-mcp-server-production.up.railway.app
```

**Or set as environment variable:**
```bash
export MCP_SERVER_URL=https://productivity-mcp-server-production.up.railway.app
```

## Testing

After fixing the deployment:

```bash
# Test health endpoint
curl https://productivity-mcp-server-production.up.railway.app/health

# Expected: {"status":"ok","service":"productivity-mcp-server"}
```
