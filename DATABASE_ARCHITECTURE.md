# Database Architecture - Current State

## Two Database Systems

### 1. MySQL/TiDB (Node.js Server)
**Purpose**: User authentication and session management

**Location**: 
- Schema: `productivity_tool_app/drizzle/schema.ts`
- DB operations: `productivity_tool_app/server/db.ts`

**Tables**:
- `users` - Stores OAuth user info
  - `id` (int, auto-increment)
  - `openId` (varchar, unique) - OAuth identifier
  - `name`, `email`, `loginMethod`
  - `role` (user/admin)
  - `createdAt`, `updatedAt`, `lastSignedIn`

**Connection**: `DATABASE_URL` environment variable

**Status**: ⚠️ **NOT CONFIGURED** - Code exists but no database connection

---

### 2. Supabase PostgreSQL (Go MCP Server)
**Purpose**: Tasks, goals, and productivity data

**Location**:
- Schema: `productivity_tool_app/supabase/migrations/001_init_schema.sql`
- Go client: `db/supabase.go`

**Tables**:
- `tasks` - Task records
- `goals` - Goal records  
- `subtasks`, `milestones`, `time_blocks`, etc.

**Connection**: `SUPABASE_URL` + `SUPABASE_ANON_KEY`

**Status**: ✅ **CONFIGURED** (if env vars are set)

---

## The Problem: User ID Mismatch

### Current Flow:
```
OAuth Login → openId (string: "user_abc123")
    ↓
Node.js Server → Stores in MySQL users table → Gets id (int: 42)
    ↓
tRPC Router → Should pass openId to Go server
    ↓
Go MCP Server → Uses openId as user_id (string: "user_abc123")
    ↓
Supabase → Expects UUID referencing auth.users(id)
    ❌ MISMATCH!
```

### Schema Expectations:

**MySQL users table:**
```sql
id INT PRIMARY KEY AUTO_INCREMENT
openId VARCHAR(64) UNIQUE  -- "user_abc123"
```

**Supabase tasks table:**
```sql
user_id UUID NOT NULL REFERENCES auth.users(id)  -- Expects UUID
```

**Go server sends:**
```go
user_id = "user_abc123"  // String, not UUID
```

## Solutions

### Solution 1: Change Supabase to Use TEXT (Quick Fix)
```sql
-- Migration to fix
ALTER TABLE tasks ALTER COLUMN user_id TYPE TEXT;
ALTER TABLE goals ALTER COLUMN user_id TYPE TEXT;
-- Remove foreign key constraints
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_user_id_fkey;
ALTER TABLE goals DROP CONSTRAINT IF EXISTS goals_user_id_fkey;
```

**Pros**: 
- Works immediately
- No new infrastructure
- Matches current OAuth flow

**Cons**:
- Loses referential integrity
- Can't use Supabase Auth features
- Manual user management

### Solution 2: Map openId to Supabase Auth UUID
Create a mapping table or use Supabase Auth:

```sql
-- Create mapping table
CREATE TABLE user_mappings (
  open_id TEXT PRIMARY KEY,
  supabase_user_id UUID REFERENCES auth.users(id)
);
```

**Pros**:
- Keeps Supabase Auth integration
- Maintains referential integrity

**Cons**:
- More complex
- Requires Supabase Auth setup
- Additional mapping logic

### Solution 3: Use MySQL user.id Instead
Pass MySQL `id` (int) instead of `openId`:

**Pros**:
- Uses existing MySQL structure
- Numeric IDs are efficient

**Cons**:
- Still need to change Supabase schema (TEXT or INT)
- Two separate user systems
- More complex

## Recommended: Solution 1 (Quick Fix)

For now, change Supabase schema to accept TEXT `user_id`:

1. **Update migration** to use TEXT
2. **Remove foreign key** constraints
3. **Use openId** directly as user_id
4. **Keep MySQL** for Node.js user management

This allows the system to work immediately while you can plan a proper Supabase Auth integration later.
