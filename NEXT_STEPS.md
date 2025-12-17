# Next Steps - Railway Deployment & Integration

## ✅ Completed
- Fixed compilation errors in `handlers/mcp.go` (responseRecorder usage)
- Removed unused imports from `handlers/task.go` and `handlers/goal.go`
- Fixed Dockerfile port configuration
- Created test scripts and documentation

## 🔄 Current Status
**Service URL:** `https://productivity-mcp-server-production.up.railway.app`  
**Status:** 502 Error (service not responding - likely needs redeploy)

## 📋 Immediate Actions Needed

### 1. Deploy the Fixes
The compilation errors are fixed, but Railway needs to rebuild:

**Option A: Git Push (Auto-deploy)**
```bash
git add .
git commit -m "Fix compilation errors in MCP handler"
git push
```

**Option B: Manual Redeploy**
- Go to Railway Dashboard → Your Service → Deployments
- Click "Redeploy" on the latest deployment

### 2. Verify Environment Variables
Ensure these are set in Railway Dashboard → Your Service → Variables:
- `SUPABASE_URL` (required)
- `SUPABASE_ANON_KEY` (required)
- `CLAUDE_API_KEY` (optional, for AI features)
- `PORT` (Railway usually sets this automatically)

### 3. Check Deployment Logs
After redeploy, check logs:
```bash
railway logs
```
Or in Railway Dashboard → Your Service → Deployments → Latest → View Logs

Look for:
- ✅ "Server running on port..."
- ❌ Any error messages about missing env vars or crashes

### 4. Test the Service
Once deployed, test:
```bash
./scripts/test_mcp_integration.sh https://productivity-mcp-server-production.up.railway.app
```

Expected:
- ✅ Health check: `{"status":"ok","service":"productivity-mcp-server"}`
- ✅ MCP Initialize: Returns protocol info
- ✅ MCP List Tools: Returns available tools

## 🔗 Webapp Integration

Once the MCP server is working, update your webapp:

### Update Environment Variables

**For local development:**
Create `productivity_tool_app/.env`:
```bash
MCP_SERVER_URL=https://productivity-mcp-server-production.up.railway.app
```

**For Railway deployment (if deploying webapp):**
Add to Railway environment variables:
```bash
MCP_SERVER_URL=https://productivity-mcp-server-production.up.railway.app
```

### Test Webapp Connection

1. **Start webapp server:**
   ```bash
   cd productivity_tool_app
   pnpm dev:server
   ```

2. **Test from webapp:**
   - Open webapp in browser
   - Try creating a task
   - Check browser console for any errors
   - Verify tasks appear in the UI

3. **Check tRPC connection:**
   The webapp uses tRPC routers that proxy to the MCP server:
   - `productivity_tool_app/server/routers/task.ts`
   - `productivity_tool_app/server/routers/goal.ts`

## 🐛 Troubleshooting

### If service still returns 502:
1. Check Railway logs for startup errors
2. Verify all environment variables are set
3. Ensure `PORT` is set (Railway usually provides this)
4. Check if service is crashing on startup

### If webapp can't connect:
1. Verify `MCP_SERVER_URL` is set correctly
2. Check CORS settings (should be handled by middleware)
3. Test MCP server directly: `curl https://productivity-mcp-server-production.up.railway.app/health`
4. Check webapp server logs for connection errors

## 📝 Files Modified

- `handlers/mcp.go` - Fixed responseRecorder usage
- `handlers/task.go` - Removed unused import
- `handlers/goal.go` - Removed unused import
- `Dockerfile` - Fixed port exposure

## 🎯 Success Criteria

- [ ] Service responds to `/health` endpoint
- [ ] MCP endpoints (`/mcp/initialize`, `/mcp/list_tools`) work
- [ ] Tasks API (`/api/tasks/*`) works
- [ ] Goals API (`/api/goals/*`) works
- [ ] Webapp can connect and create tasks/goals
- [ ] End-to-end test passes
