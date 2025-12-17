# Security Fixes Applied ✅

## 🔒 Security Concerns Addressed

You were absolutely right to question using OAuth identifiers as foreign keys. Here's what I fixed:

## ✅ What Was Fixed

### 1. **Use Internal IDs, Not External Identifiers**

**Before (INSECURE):**
- Using `openId` (OAuth identifier) as `user_id` in Supabase
- External identifier exposed in database
- Potential privacy/security issues

**After (SECURE):**
- Using MySQL `user.id` (internal integer) as `user_id`
- Internal database ID, not PII
- OAuth `openId` stays in MySQL only, never exposed

### 2. **Authentication Required**

**Before:**
- Routers used `publicProcedure` (no auth required)
- Fallback to `"default-user"` if no user
- Anyone could access data

**After:**
- Routers use `protectedProcedure` (auth required)
- Throws `UNAUTHORIZED` if not authenticated
- User ID comes from authenticated context

### 3. **Database Schema Fixed**

**Migration Created:** `supabase/migrations/002_fix_user_id_type.sql`
- Changes `user_id` from `UUID` to `INTEGER`
- Removes foreign key to `auth.users` (we're using MySQL)
- Uses MySQL `user.id` (internal integer)

## 🔐 Secure Data Flow

```
User Login via OAuth
  ↓
OAuth Provider → Returns openId: "user_abc123"
  ↓
Node.js Server → MySQL Query
  SELECT id FROM users WHERE openId = 'user_abc123'
  Returns: id = 42 (internal integer)
  ↓
Session Created → Stores MySQL user.id (42) in JWT
  ↓
API Request → tRPC Context
  ctx.user.id = 42 (MySQL internal ID)
  ↓
tRPC Router (protectedProcedure) → Validates auth
  Uses ctx.user.id (42) - secure, not PII
  ↓
Go MCP Server → Receives "42" as user_id
  ↓
Supabase → Stores task with user_id = 42 (INTEGER)
  ✅ SECURE: Internal ID, not external identifier
```

## 📋 Changes Made

### Files Updated:

1. **`server/routers/task.ts`**
   - Changed `publicProcedure` → `protectedProcedure`
   - Removed `userId` from input schemas
   - Uses `ctx.user.id` (MySQL internal ID)

2. **`server/routers/goal.ts`**
   - Changed `publicProcedure` → `protectedProcedure`
   - Removed `userId` from input schemas
   - Uses `ctx.user.id` (MySQL internal ID)

3. **`hooks/use-tasks-api.ts`**
   - Removed `userId` parameter
   - Queries get user ID from auth context automatically

4. **`hooks/use-goals-api.ts`**
   - Removed `userId` parameter
   - Queries get user ID from auth context automatically

5. **`supabase/migrations/002_fix_user_id_type.sql`** (NEW)
   - Migration to change `user_id` from UUID to INTEGER
   - Removes foreign key constraints
   - Adds proper indexes

## 🔒 Security Benefits

1. **No PII in Foreign Keys**
   - Uses internal database IDs (integers)
   - OAuth identifiers stay in MySQL only

2. **Authentication Required**
   - All routes require valid session
   - No anonymous access

3. **Proper Separation**
   - Auth system (MySQL) separate from data (Supabase)
   - Can migrate systems independently

4. **Type Safety**
   - Integer IDs are efficient and type-safe
   - No string comparison overhead

## ⚠️ Still Needed

### 1. MySQL Database Setup
The Node.js server needs a MySQL/TiDB database:
- Set `DATABASE_URL` environment variable
- Run migrations: `pnpm db:push`
- Creates `users` table for auth

### 2. Supabase Migration
Run the new migration in Supabase:
```sql
-- Run in Supabase SQL Editor
\i supabase/migrations/002_fix_user_id_type.sql
```

### 3. RLS Policies
Update Row Level Security policies to work with INTEGER `user_id`:
- Current policies expect UUID
- Need to update or disable for now

## ✅ What's Secure Now

- ✅ Internal IDs used (not external identifiers)
- ✅ Authentication required for all operations
- ✅ OAuth `openId` never exposed to Supabase
- ✅ Proper type safety (INTEGER vs UUID)
- ✅ Separation of auth and data systems

## 🎯 Next Steps

1. **Set up MySQL database** for Node.js server
2. **Run Supabase migration** to change user_id type
3. **Update RLS policies** or disable for development
4. **Test authentication flow** end-to-end
