# Cloudflare OAuth Security Fixes Applied

## Critical Fixes (CVE-2025-4143)

### 1. Redirect URI Validation (REQUIRED in Token Exchange)

**Before:**
```go
// Optional validation
if req.RedirectURI != "" && req.RedirectURI != authCodeData.RedirectURI {
    // reject
}
```

**After (Cloudflare Pattern):**
```go
// REQUIRED validation (prevents open redirect attacks)
if req.RedirectURI == "" {
    // reject - redirect_uri is required
}
if req.RedirectURI != authCodeData.RedirectURI {
    // reject - must match exactly
}
```

**Why:** Cloudflare's CVE-2025-4143 showed that missing redirect_uri validation in token exchange allows open redirect attacks.

### 2. Exact Match Enforcement

**Requirement:** redirect_uri must match character-for-character between authorization and token exchange.

**Implementation:**
- Store redirect_uri with auth code
- Require redirect_uri in token request
- Compare exact strings (no normalization)
- Reject any mismatch

### 3. Security Headers Added

**Per Cloudflare Best Practices:**
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security` (HTTPS only)

### 4. Redirect URI Whitelist

**Official Claude URIs (Exact Match Only):**
- `https://claude.ai/api/mcp/auth_callback` ✅
- `https://claude.com/api/mcp/auth_callback` ✅
- `claude://oauth-callback` ✅

**No Wildcards:** Per Cloudflare security, exact match only.

## Testing Checklist

After deployment, verify:

1. **Authorization with redirect_uri:**
   ```bash
   curl "https://productivity-mcp-server-production.up.railway.app/authorize?client_id=claude-desktop&redirect_uri=https://claude.ai/api/mcp/auth_callback&response_type=code&state=test"
   ```
   Should redirect to `https://claude.ai/api/mcp/auth_callback?code=...&state=test`

2. **Token exchange with matching redirect_uri:**
   ```bash
   curl -X POST https://productivity-mcp-server-production.up.railway.app/oauth/token \
     -H "Content-Type: application/json" \
     -d '{
       "grant_type": "authorization_code",
       "code": "AUTH_CODE",
       "redirect_uri": "https://claude.ai/api/mcp/auth_callback"
     }'
   ```
   Should succeed if redirect_uri matches

3. **Token exchange with mismatched redirect_uri:**
   ```bash
   curl -X POST https://productivity-mcp-server-production.up.railway.app/oauth/token \
     -H "Content-Type: application/json" \
     -d '{
       "grant_type": "authorization_code",
       "code": "AUTH_CODE",
       "redirect_uri": "https://evil.com/callback"
     }'
   ```
   Should reject with "redirect_uri does not match"

4. **Token exchange without redirect_uri:**
   ```bash
   curl -X POST https://productivity-mcp-server-production.up.railway.app/oauth/token \
     -H "Content-Type: application/json" \
     -d '{
       "grant_type": "authorization_code",
       "code": "AUTH_CODE"
     }'
   ```
   Should reject with "redirect_uri is required"

## Security Improvements

✅ **Open Redirect Prevention** - redirect_uri validated in both phases  
✅ **Exact Match Required** - No wildcards or normalization  
✅ **Security Headers** - XSS, clickjacking protection  
✅ **HSTS** - Force HTTPS where applicable  

## Next Steps

1. Wait for Railway deployment (2-3 minutes)
2. Test OAuth flow end-to-end
3. Verify redirect_uri validation works
4. Test in Claude Desktop
5. If still fails → Pivot to Desktop Extension

## Desktop Extension Backup Plan

If OAuth continues to fail, see:
- `docs/CLAUDE_DESKTOP_EXTENSION_PLAN.md` - Full extension development plan
