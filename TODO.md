# TODO - Productivity MCP Server

## 🔴 Critical - Must Complete

### 1. Supabase Setup
- [ ] Create new Supabase project
- [ ] Run migration: `productivity_tool_app/supabase/migrations/001_clean_schema.sql`
- [ ] Get `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- [ ] Add credentials to Railway environment variables
- [ ] Test Supabase connection

### 2. MySQL Database Setup (Node.js Server)
- [ ] Create MySQL/TiDB database
- [ ] Set `DATABASE_URL` environment variable
- [ ] Run `pnpm db:push` in `productivity_tool_app/` to create users table
- [ ] Test database connection

### 3. OAuth 2.0 Implementation (MCP Server)
- [ ] **Client Registration System**
  - [ ] Create database table for OAuth clients
  - [ ] Implement client registration endpoint
  - [ ] Validate client_id and client_secret
  - [ ] Validate redirect_uri against registered clients

- [ ] **Authorization Code Storage**
  - [ ] Store auth codes in database/cache
  - [ ] Set expiration (10 minutes)
  - [ ] Track code usage (one-time use)
  - [ ] Link codes to user_id and client_id

- [ ] **User Authentication Flow**
  - [ ] Show consent screen if user not logged in
  - [ ] Require user login before OAuth consent
  - [ ] Link OAuth flow to existing user system (MySQL)
  - [ ] Map OAuth tokens to MySQL user.id

- [ ] **Token Management**
  - [ ] Store refresh tokens in database
  - [ ] Track token expiration
  - [ ] Implement token revocation
  - [ ] Extract user_id from token claims in middleware

- [ ] **Environment Variables**
  - [ ] Set `JWT_SECRET` in Railway (generate secure key)
  - [ ] Document all required env vars

## 🟡 Important - Should Complete

### 4. Integration Testing
- [ ] Test OAuth flow end-to-end
- [ ] Test MCP endpoints with authentication
- [ ] Test task creation via MCP
- [ ] Test goal creation via MCP
- [ ] Verify user_id mapping (MySQL → Supabase)

### 5. Claude Desktop Configuration
- [ ] Register MCP server as OAuth client
- [ ] Get client_id and client_secret
- [ ] Add server to Claude Desktop via Settings > Connectors
- [ ] Test connection from Claude Desktop
- [ ] Verify tools are available in Claude

### 6. Error Handling & Logging
- [ ] Add proper error responses for OAuth failures
- [ ] Add logging for OAuth flow
- [ ] Add logging for MCP requests
- [ ] Handle token expiration gracefully
- [ ] Handle invalid tokens gracefully

## 🟢 Nice to Have

### 7. Security Enhancements
- [ ] Implement rate limiting for OAuth endpoints
- [ ] Add CSRF protection for OAuth flow
- [ ] Implement token refresh flow
- [ ] Add token revocation endpoint
- [ ] Secure JWT secret (use strong random key)

### 8. Documentation
- [ ] Update README with OAuth setup instructions
- [ ] Document OAuth client registration process
- [ ] Create API documentation for OAuth endpoints
- [ ] Add troubleshooting guide

### 9. Code Quality
- [ ] Add unit tests for OAuth handlers
- [ ] Add integration tests for MCP endpoints
- [ ] Review and clean up TODO comments
- [ ] Add proper error types
- [ ] Improve error messages

## 📋 Quick Reference

### Environment Variables Needed

**Go MCP Server (Railway):**
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
CLAUDE_API_KEY=your-claude-key
JWT_SECRET=your-secure-jwt-secret
PORT=8080
```

**Node.js Server (Local/Deploy):**
```bash
DATABASE_URL=mysql://user:pass@host:port/dbname
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
MCP_SERVER_URL=https://productivity-mcp-server-production.up.railway.app
JWT_SECRET=your-secure-jwt-secret
OAUTH_SERVER_URL=your-oauth-url
VITE_APP_ID=your-app-id
```

### Key Files to Update

- `handlers/auth.go` - Complete OAuth implementation
- `middleware/auth.go` - Complete token validation
- `db/supabase.go` - Already done ✅
- `handlers/mcp.go` - Already done ✅
- `main.go` - OAuth routes added ✅

### Testing Checklist

1. **Supabase:**
   ```bash
   curl https://your-project.supabase.co/rest/v1/tasks?select=*&limit=1
   ```

2. **Go MCP Server:**
   ```bash
   curl https://productivity-mcp-server-production.up.railway.app/health
   ```

3. **OAuth Flow:**
   ```bash
   # 1. Get auth code
   curl "https://your-server.com/oauth/authorize?client_id=test&redirect_uri=http://localhost&response_type=code&state=xyz"
   
   # 2. Exchange for token
   curl -X POST https://your-server.com/oauth/token \
     -H "Content-Type: application/json" \
     -d '{"grant_type":"authorization_code","code":"AUTH_CODE"}'
   
   # 3. Use token
   curl -X POST https://your-server.com/mcp/initialize \
     -H "Authorization: Bearer TOKEN"
   ```

## 🎯 Priority Order

1. **Supabase setup** (blocks everything)
2. **MySQL setup** (blocks Node.js server)
3. **OAuth client registration** (blocks Claude Desktop)
4. **OAuth flow completion** (required for production)
5. **Integration testing** (verify everything works)
6. **Claude Desktop connection** (end goal)

## 📝 Notes

- OAuth endpoints are implemented but need database integration
- MCP endpoints are protected with auth middleware
- User ID mapping (MySQL → Supabase) needs to be completed
- All security fixes are in place (using MySQL user.id, not openId)
