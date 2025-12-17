# MCP OAuth 2.0 Authentication Setup

## Overview

For remote MCP servers, Anthropic requires **OAuth 2.0 authentication**. This document explains the implementation and setup.

## OAuth 2.0 Flow

### 1. Authorization Request
```
GET /oauth/authorize?client_id=xxx&redirect_uri=xxx&response_type=code&scope=read+write&state=xxx
```

**Parameters:**
- `client_id` - Client identifier (register your MCP server)
- `redirect_uri` - Where to redirect after authorization
- `response_type=code` - Authorization code flow
- `scope` - Permissions requested (e.g., "read write")
- `state` - CSRF protection token

**Response:** Redirects to `redirect_uri?code=AUTH_CODE&state=xxx`

### 2. Token Exchange
```
POST /oauth/token
Content-Type: application/json

{
  "grant_type": "authorization_code",
  "code": "AUTH_CODE",
  "client_id": "xxx",
  "client_secret": "xxx"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGci...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "refresh_token_xxx",
  "scope": "read write"
}
```

### 3. Using Access Token
All MCP endpoints require the access token in the Authorization header:
```
Authorization: Bearer <access_token>
```

## Implementation Status

### ✅ Implemented
- OAuth authorization endpoint (`/oauth/authorize`)
- OAuth token endpoint (`/oauth/token`)
- Token introspection endpoint (`/oauth/introspect`)
- JWT token generation and validation
- Auth middleware for MCP endpoints

### ⚠️ TODO (Required for Production)
1. **Client Registration**
   - Store registered clients (client_id, client_secret, redirect_uris)
   - Validate client_id and client_secret
   - Validate redirect_uri

2. **Authorization Code Storage**
   - Store auth codes in database/cache with expiration (10 minutes)
   - Track which codes have been used (one-time use)
   - Link codes to user_id and client_id

3. **User Authentication**
   - Show consent screen if user not logged in
   - Require user to authenticate before granting access
   - Link OAuth flow to your existing user system

4. **Token Storage**
   - Store refresh tokens in database
   - Track token expiration
   - Implement token revocation

5. **User ID Mapping**
   - Map OAuth tokens to MySQL user.id
   - Extract user_id from token claims
   - Pass user_id to MCP handlers

## Environment Variables

Add to your `.env` and Railway:

```bash
JWT_SECRET=your-very-secure-random-secret-key-here
```

**Generate a secure secret:**
```bash
openssl rand -base64 32
```

## For Claude Desktop

When adding your MCP server in Claude Desktop:

1. **Settings > Connectors > Add Connector**
2. **Server URL:** `https://productivity-mcp-server-production.up.railway.app`
3. **Authentication:** OAuth 2.0
4. **Client ID:** (register your server first)
5. **Client Secret:** (from registration)
6. **Authorization URL:** `https://productivity-mcp-server-production.up.railway.app/oauth/authorize`
7. **Token URL:** `https://productivity-mcp-server-production.up.railway.app/oauth/token`

## Testing OAuth Flow

### 1. Get Authorization Code
```bash
curl "https://your-server.com/oauth/authorize?client_id=test&redirect_uri=http://localhost&response_type=code&state=xyz"
```

### 2. Exchange Code for Token
```bash
curl -X POST https://your-server.com/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "authorization_code",
    "code": "AUTH_CODE_FROM_STEP_1",
    "client_id": "test"
  }'
```

### 3. Use Token
```bash
curl -X POST https://your-server.com/mcp/initialize \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json"
```

## Next Steps

1. **Implement client registration** - Store clients in database
2. **Add user authentication** - Require login before OAuth consent
3. **Link to MySQL users** - Map OAuth tokens to user.id
4. **Test with Claude Desktop** - Complete OAuth flow end-to-end
