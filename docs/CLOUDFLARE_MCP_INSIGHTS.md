# Cloudflare MCP OAuth Best Practices

## Critical Security Requirements (CVE-2025-4143)

Based on Cloudflare's OAuth Provider Library and security advisories:

### 1. Redirect URI Validation (CRITICAL)

**Must validate `redirect_uri` in BOTH phases:**

1. **Authorization Request** (`/authorize`)
   - ✅ Validate redirect_uri format
   - ✅ Validate redirect_uri is registered for client
   - ✅ Store redirect_uri with auth code

2. **Token Exchange** (`/oauth/token`)
   - ✅ Validate redirect_uri matches the one used in authorization
   - ✅ Reject if redirect_uri doesn't match stored value
   - ⚠️ **This prevents open redirect attacks**

### 2. Redirect URI Matching Rules

**Exact Match Required:**
- Must match character-for-character
- Query parameters in redirect_uri must match
- Scheme, host, path must all match exactly

**Example:**
```
Authorization: redirect_uri=https://claude.ai/api/mcp/auth_callback
Token Exchange: redirect_uri=https://claude.ai/api/mcp/auth_callback ✅

Authorization: redirect_uri=https://claude.ai/api/mcp/auth_callback
Token Exchange: redirect_uri=https://claude.com/api/mcp/auth_callback ❌ (different host)
```

### 3. Supported Redirect URIs (Claude Desktop)

Based on Cloudflare and Anthropic documentation:

**Official Claude URIs:**
- `https://claude.ai/api/mcp/auth_callback` ✅
- `https://claude.com/api/mcp/auth_callback` ✅
- `claude://oauth-callback` ✅ (custom scheme for native app)

**Development URIs:**
- `http://localhost` ✅
- `http://localhost:PORT` ✅

### 4. OAuth 2.1 Flow (Cloudflare Pattern)

```
1. Client → GET /authorize
   - client_id
   - redirect_uri (validated)
   - code_challenge (PKCE)
   - state
   
2. Server → Redirect to redirect_uri?code=XXX&state=YYY
   - Store: code, redirect_uri, code_challenge, client_id
   
3. Client → POST /oauth/token
   - code
   - code_verifier (PKCE)
   - redirect_uri (MUST match authorization)
   
4. Server → Validate:
   - Code exists and not expired
   - Code not already used
   - redirect_uri matches stored value ⚠️ CRITICAL
   - code_verifier matches code_challenge
   
5. Server → Return access_token
```

### 5. Token Storage (Cloudflare Pattern)

**Cloudflare uses:**
- Workers KV for encrypted token storage
- Tokens encrypted before storage
- Secure key management

**Our Implementation:**
- Currently in-memory (for development)
- TODO: Move to database with encryption
- TODO: Implement token revocation

### 6. Security Headers

**Cloudflare recommends:**
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security` (if HTTPS)

## Implementation Checklist

- [x] Validate redirect_uri in authorization
- [x] Store redirect_uri with auth code
- [x] Validate redirect_uri in token exchange
- [x] Reject mismatched redirect_uri
- [x] Support Claude official URIs
- [x] Support custom schemes (claude://)
- [x] PKCE validation (S256)
- [ ] Token encryption (TODO)
- [ ] Token revocation endpoint (TODO)
- [ ] Security headers middleware (TODO)

## Common Issues

### Issue 1: Redirect URI Mismatch

**Symptom:** Token exchange fails with "redirect_uri does not match"

**Cause:** redirect_uri in token request doesn't exactly match authorization

**Fix:** Ensure exact match, including:
- Scheme (http vs https)
- Host (claude.ai vs claude.com)
- Path (exact path match)
- No extra query parameters

### Issue 2: Open Redirect Vulnerability

**Symptom:** Can redirect to arbitrary URLs

**Cause:** Not validating redirect_uri against whitelist

**Fix:** 
- Maintain whitelist of allowed redirect URIs per client
- Validate in BOTH authorization and token exchange
- Reject any redirect_uri not in whitelist

### Issue 3: Missing PKCE Validation

**Symptom:** Authorization works but token exchange fails

**Cause:** Code challenge stored but not validated

**Fix:**
- Store code_challenge with auth code
- Validate code_verifier matches code_challenge
- Use S256 method (SHA256 hash)

## Next Steps

1. ✅ Implement redirect_uri validation in token exchange
2. ✅ Ensure exact matching
3. ⏳ Add security headers
4. ⏳ Implement token encryption
5. ⏳ Add token revocation

## Desktop Extension Alternative

If MCP OAuth continues to fail, consider:

**Claude Desktop Extension:**
- Native integration
- No OAuth complexity
- Direct API access
- Better performance
- Easier debugging

**Trade-offs:**
- Requires extension development
- Distribution via extension store
- Less flexible than MCP
