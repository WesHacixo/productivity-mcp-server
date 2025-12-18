# Claude Desktop Setup - OAuth 2.1 with PKCE ✅

## What's Fixed

✅ **OAuth 2.1 Implementation** - Full PKCE support (code_challenge/code_verifier)  
✅ **`/authorize` Route** - Claude Desktop calls this (not `/oauth/authorize`)  
✅ **Claude Redirect URIs** - Supports `https://claude.ai/api/mcp/auth_callback`  
✅ **PKCE Validation** - S256 method with proper SHA256 verification  
✅ **Security** - One-time use auth codes, expiration, redirect_uri validation  

## Quick Setup

### In Claude Desktop:

1. **Connector Name:** `Productivity MCP`
2. **Remote MCP Server URL:** `https://productivity-mcp-server-production.up.railway.app`
3. **Advanced Settings:**
   - **OAuth Client ID:** `claude-desktop` (optional)
   - **OAuth Client Secret:** `claude-desktop-secret-dev` (optional)

**That's it!** Claude Desktop will:
- Auto-discover OAuth endpoints from `/.well-known/oauth-authorization-server`
- Use PKCE (S256) automatically
- Handle the OAuth 2.1 flow

## OAuth 2.1 Features Implemented

### 1. PKCE (Proof Key for Code Exchange)

**Authorization Request:**
```
GET /authorize?
  client_id=claude-desktop&
  redirect_uri=https://claude.ai/api/mcp/auth_callback&
  response_type=code&
  code_challenge=FhvQntlE9DhR513WTkCdKBXxA24iITPjGd2NKdTJTvk&
  code_challenge_method=S256&
  state=EBtEBKF951WZMQxSOLt-9jpI9f5vl51djzH1AI4oUPY&
  scope=claudeai
```

**Token Exchange:**
```
POST /oauth/token
{
  "grant_type": "authorization_code",
  "code": "AUTH_CODE",
  "code_verifier": "code_verifier_here",
  "redirect_uri": "https://claude.ai/api/mcp/auth_callback"
}
```

**Validation:**
- Server stores `code_challenge` with auth code
- Client sends `code_verifier` at token exchange
- Server validates: `SHA256(code_verifier) == code_challenge`

### 2. Supported Redirect URIs

✅ `https://claude.ai/api/mcp/auth_callback`  
✅ `https://claude.com/api/mcp/auth_callback`  
✅ `claude://oauth-callback`  
✅ `http://localhost` (for development)

### 3. Security Features

- ✅ **PKCE Required** - Prevents authorization code interception
- ✅ **One-Time Use Codes** - Auth codes can only be used once
- ✅ **Code Expiration** - Codes expire after 10 minutes
- ✅ **Redirect URI Validation** - Must match registered URIs
- ✅ **State Parameter** - CSRF protection
- ✅ **JWT Tokens** - Secure token generation

## OAuth Discovery

Claude Desktop automatically discovers:

```
GET /.well-known/oauth-authorization-server
```

**Response:**
```json
{
  "issuer": "https://productivity-mcp-server-production.up.railway.app",
  "authorization_endpoint": "https://productivity-mcp-server-production.up.railway.app/authorize",
  "token_endpoint": "https://productivity-mcp-server-production.up.railway.app/oauth/token",
  "code_challenge_methods_supported": ["S256", "plain"],
  "grant_types_supported": ["authorization_code", "refresh_token"],
  "scopes_supported": ["read", "write", "mcp", "claudeai"]
}
```

## Testing

### Test Authorization Endpoint

```bash
curl "https://productivity-mcp-server-production.up.railway.app/authorize?client_id=claude-desktop&redirect_uri=https://claude.ai/api/mcp/auth_callback&response_type=code&code_challenge=FhvQntlE9DhR513WTkCdKBXxA24iITPjGd2NKdTJTvk&code_challenge_method=S256&state=test123&scope=claudeai"
```

Should redirect to: `https://claude.ai/api/mcp/auth_callback?code=...&state=test123`

### Test Token Exchange

```bash
curl -X POST https://productivity-mcp-server-production.up.railway.app/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "authorization_code",
    "code": "AUTH_CODE_FROM_ABOVE",
    "code_verifier": "code_verifier_that_matches_challenge",
    "redirect_uri": "https://claude.ai/api/mcp/auth_callback"
  }'
```

## What Changed

### Before (OAuth 2.0)
- ❌ Only `/oauth/authorize` route
- ❌ No PKCE support
- ❌ Missing Claude redirect URIs
- ❌ No code_verifier validation

### After (OAuth 2.1)
- ✅ Both `/authorize` and `/oauth/authorize` routes
- ✅ Full PKCE support (S256 method)
- ✅ Claude redirect URIs supported
- ✅ Proper code_verifier validation
- ✅ One-time use codes
- ✅ Code expiration

## Claude iOS Support

The same OAuth 2.1 implementation works for Claude iOS:
- Same PKCE flow
- Same redirect URIs
- Same token exchange

**Future:** Orchestration between Claude iOS → MCP Server → Claude Desktop 🚀

## Deployment

After deploying, Claude Desktop will:
1. Auto-discover OAuth endpoints
2. Use PKCE automatically
3. Complete OAuth 2.1 flow
4. Connect successfully! ✅

## Troubleshooting

### "404 on /authorize"

**Fix:** Make sure latest code is deployed with `/authorize` route

### "PKCE validation failed"

**Fix:** Ensure `code_verifier` matches the `code_challenge` used in authorization

### "redirect_uri not registered"

**Fix:** Use one of the supported URIs:
- `https://claude.ai/api/mcp/auth_callback`
- `https://claude.com/api/mcp/auth_callback`
- `claude://oauth-callback`

## Summary

✅ **OAuth 2.1** - Fully implemented  
✅ **PKCE** - S256 method with proper validation  
✅ **Claude URIs** - All supported redirect URIs  
✅ **Security** - One-time codes, expiration, validation  
✅ **Auto-Discovery** - Claude Desktop finds everything automatically  

**Ready for production!** 🚀
