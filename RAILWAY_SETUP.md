# Railway Deployment Setup

This guide helps you configure the Go MCP server on Railway and connect the webapp to it.

## Railway Deployment

### 1. Environment Variables in Railway

In your Railway project dashboard, set these environment variables:

```bash
# Required
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
CLAUDE_API_KEY=sk-ant-your-api-key

# Optional (Railway sets PORT automatically)
PORT=8080
GIN_MODE=release
```

### 2. Get Your Railway URL

After deployment, Railway provides a public URL like:
- `https://your-app-name.up.railway.app`

**To find your URL:**

1. Go to your Railway project: https://railway.com/project/6e921b3a-2d3e-4aa8-af94-cfa4f48cc5a5
2. Click on the **"productivity-mcp-server"** service
3. Go to the **"Settings"** tab
4. Scroll to the **"Domains"** section
5. Your public URL will be listed there (e.g., `https://productivity-mcp-server-production.up.railway.app`)

**Alternative:** Check the "Deployments" tab - Railway shows the generated URL for each deployment.

### 3. Update Webapp Configuration

Once you have your Railway URL, update the webapp's Node.js server environment:

**In `productivity_tool_app/.env` or Railway environment:**
```bash
MCP_SERVER_URL=https://your-app-name.up.railway.app
```

**Or if using Railway for the webapp too:**
- Add `MCP_SERVER_URL` as an environment variable pointing to your Go MCP server service

### 4. Test the Deployment

```bash
# Test health endpoint
curl https://your-app-name.up.railway.app/health

# Should return:
# {"status":"ok","service":"productivity-mcp-server"}

# Test MCP initialize
curl -X POST https://your-app-name.up.railway.app/mcp/initialize
```

## Railway-Specific Configuration

### Port Configuration

Railway automatically sets the `PORT` environment variable. The Go server reads this:

```go
port := os.Getenv("PORT")
if port == "" {
    port = "8080"  // Fallback
}
```

### CORS Configuration

The Go server's CORS middleware allows all origins by default. For production, you may want to restrict this:

```go
// In middleware/cors.go
c.Writer.Header().Set("Access-Control-Allow-Origin", "https://your-webapp-domain.com")
```

### Health Checks

Railway uses the `/health` endpoint for health checks. This is already implemented:

```go
router.GET("/health", func(c *gin.Context) {
    c.JSON(200, gin.H{
        "status": "ok",
        "service": "productivity-mcp-server",
    })
})
```

## Connecting the Webapp

### Option 1: Same Railway Project (Recommended)

If both services are in the same Railway project:

1. **Go MCP Server Service:**
   - Environment: `PORT=8080` (or let Railway set it)
   - No additional config needed

2. **Webapp Node.js Server Service:**
   - Environment: `MCP_SERVER_URL=http://your-mcp-service.railway.internal:8080`
   - Or use the public URL: `MCP_SERVER_URL=https://your-mcp-service.up.railway.app`

### Option 2: Different Projects/Deployments

If services are separate:

1. **Go MCP Server:**
   - Deploy to Railway
   - Get public URL: `https://mcp-server.up.railway.app`

2. **Webapp Server:**
   - Set `MCP_SERVER_URL=https://mcp-server.up.railway.app`
   - Deploy to Railway or your preferred platform

## Monitoring

### Railway Dashboard

- **Logs**: View real-time logs in Railway dashboard
- **Metrics**: CPU, Memory, Network usage
- **Deployments**: Track deployment history

### Health Monitoring

Railway automatically monitors:
- Service uptime
- Response times
- Error rates

Set up alerts in Railway dashboard for:
- High error rates
- Service downtime
- Resource limits

## Troubleshooting

### Service Not Starting

1. Check Railway logs:
   - Dashboard → Your Service → Logs
   - Look for startup errors

2. Common issues:
   - Missing environment variables
   - Port conflicts (Railway handles this automatically)
   - Database connection failures

### Connection Timeouts

1. Verify Railway URL is correct
2. Check CORS settings if calling from browser
3. Ensure service is running (check logs)

### Environment Variables Not Working

1. Railway requires variables to be set in the dashboard
2. Variables set in `.env` files are NOT automatically loaded
3. Set them in: Dashboard → Your Service → Variables

## Updating Deployment

Railway automatically redeploys on:
- Git push to connected branch (usually `main`)
- Manual trigger from dashboard

To update:
1. Push changes to GitHub
2. Railway detects changes
3. Automatically builds and deploys
4. New deployment is live in ~2-3 minutes

## Cost Optimization

### Free Tier
- $5 credit/month
- Sufficient for development and small teams

### Scaling
- Railway auto-scales based on traffic
- Pay only for what you use
- Monitor usage in dashboard

## Next Steps

1. ✅ Deploy Go MCP server to Railway
2. ✅ Get Railway URL
3. ✅ Set `MCP_SERVER_URL` in webapp environment
4. ✅ Test connection
5. ✅ Deploy webapp (if using Railway)
6. ✅ Monitor logs and metrics

For more help, see [Railway Documentation](https://docs.railway.app)
