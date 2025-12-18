# Route Debugging - 404 Issues

## Problem
All routes return 404 except `/health`, even though routes are registered in code.

## Possible Causes

### 1. Railway Build Issue
- Latest code might not be built
- Check Railway deployment logs
- Verify commit hash matches deployed version

### 2. Route Registration Order
- Routes registered after middleware (should be fine)
- But check if middleware is blocking

### 3. `.well-known` Path Issue
- Gin might have issues with dots in paths
- May need special handling

### 4. Binary Name Mismatch
- Railway builds `server` binary
- Check if correct binary is running

## Debugging Steps

### Check Railway Logs
1. Railway Dashboard → Your Service → Logs
2. Look for "Route registered" messages
3. Check for any build errors
4. Verify server started successfully

### Test Locally
```bash
go run main.go
# In another terminal:
curl http://localhost:8080/.well-known/oauth-authorization-server
curl http://localhost:8080/authorize?client_id=test
```

### Verify Build
```bash
# Check what Railway built
git show HEAD:main.go | grep "OAuth 2.1"
# Should show the routes
```

## Quick Fix Attempts

1. **Move routes before middleware** (unlikely to help, but worth trying)
2. **Add explicit route logging** (done - check logs)
3. **Verify Railway is using latest commit**
4. **Check if binary name matches** (`server` vs `mcp-server`)

## Next Steps

1. Check Railway deployment logs
2. Verify routes are in deployed code
3. Test locally to confirm routes work
4. If local works but Railway doesn't → build/deployment issue
5. If local doesn't work → code issue
