# Original vs Current Structure Comparison

## 🔍 Key Discovery: **DUAL DATABASE SYSTEM**

The webapp uses **TWO separate databases**:

### 1. **MySQL/TiDB Database** (Node.js Server)
- **Purpose**: User management for the Node.js backend
- **Location**: `server/db.ts`, `drizzle/schema.ts`
- **Connection**: `DATABASE_URL` environment variable
- **Schema**: `users` table with `id`, `openId`, `name`, `email`, etc.
- **ORM**: Drizzle ORM (MySQL dialect)
- **Used by**: OAuth authentication, user session management

### 2. **Supabase PostgreSQL** (Go MCP Server)
- **Purpose**: Tasks, goals, and productivity data
- **Location**: `db/supabase.go` (Go server)
- **Connection**: `SUPABASE_URL` + `SUPABASE_ANON_KEY`
- **Schema**: `tasks`, `goals`, `subtasks`, `milestones`, etc.
- **ORM**: Direct HTTP REST API calls
- **Used by**: Go MCP server for all task/goal operations

## 📋 Missing from Original Structure

Based on the file explorer image, these files appear to be missing:

### Documentation Files
- ❌ `ARCHITECTURE.md` - Architecture overview
- ❌ `LOCAL_SETUP.md` - Local development setup guide
- ❌ `DOWNLOAD_README.md` - Download/setup instructions

### Configuration
- ✅ `.env` - Should exist (might be gitignored)
- ✅ `drizzle.config.ts` - Exists
- ✅ `drizzle/schema.ts` - Exists (but only has `users` table)

## 🔧 Critical Issues Found

### 1. **Database Schema Mismatch** ⚠️ CRITICAL

**Problem:**
- **Supabase migration** (`supabase/migrations/001_init_schema.sql`):
  - Uses `user_id UUID REFERENCES auth.users(id)`
  - Expects Supabase Auth integration
  
- **Go MCP Server** (`db/supabase.go`):
  - Sends `user_id` as TEXT/string
  - Uses `openId` from OAuth (not Supabase Auth UUID)
  
- **Node.js Server** (`drizzle/schema.ts`):
  - Has `users` table with `openId` (string)
  - Uses MySQL, not Supabase

**The Issue:**
- Go server sends `user_id` as TEXT (e.g., `"user_abc123"`)
- Supabase expects UUID that references `auth.users(id)`
- These don't match!

### 2. **Missing MySQL/TiDB Database** ⚠️

**What's Missing:**
- `DATABASE_URL` environment variable for MySQL
- MySQL/TiDB database instance
- User table in MySQL (for Node.js server auth)

**Current State:**
- Code exists to use MySQL (`server/db.ts`)
- But no MySQL database is configured
- Auth will fail if `DATABASE_URL` is missing

### 3. **Auth Flow Disconnect** ⚠️

**The Flow Should Be:**
1. User logs in via OAuth → Gets `openId` (string)
2. Node.js server stores user in MySQL → Gets `id` (int)
3. Node.js server passes `openId` to Go MCP server
4. Go MCP server uses `openId` as `user_id` in Supabase

**Current Problem:**
- Step 2 might fail (no MySQL DB)
- Step 4 will fail (Supabase expects UUID, not `openId` string)

## ✅ What We Have

### Complete Systems
- ✅ OAuth authentication (Manus)
- ✅ AsyncStorage for local persistence
- ✅ tRPC API layer
- ✅ React Native/Expo frontend
- ✅ Go MCP server structure
- ✅ Supabase migration files

### Missing/Incomplete
- ❌ MySQL/TiDB database setup
- ❌ Database schema alignment (UUID vs TEXT vs openId)
- ❌ Auth-to-MCP user ID mapping
- ❌ Documentation files

## 🎯 What Needs to Be Fixed

### Option A: Use Supabase for Everything (Simpler)
1. Remove MySQL dependency
2. Use Supabase Auth instead of separate user table
3. Map OAuth `openId` to Supabase `auth.users`
4. Change Go server to use Supabase Auth UUIDs

### Option B: Keep Dual Database (More Complex)
1. Set up MySQL/TiDB database
2. Keep user management in MySQL
3. Create mapping between `openId` (MySQL) and Supabase `user_id`
4. Update Go server to accept both formats

### Option C: Use openId as user_id (Quick Fix)
1. Change Supabase schema to use `TEXT` instead of `UUID`
2. Remove foreign key to `auth.users`
3. Use `openId` directly as `user_id` in Supabase
4. Keep MySQL for Node.js server user management

## 📝 Recommended Approach

**Option C is the quickest fix** for now:
- Minimal schema changes
- No new database needed
- Works with existing OAuth flow
- Can migrate to Supabase Auth later if needed

## 🔍 Files to Check from Original

If you have access to the original repo, check for:
1. `ARCHITECTURE.md` - Might explain the dual database setup
2. `LOCAL_SETUP.md` - Database setup instructions
3. `.env.example` - Required environment variables
4. MySQL/TiDB connection details
5. Any user ID mapping logic
