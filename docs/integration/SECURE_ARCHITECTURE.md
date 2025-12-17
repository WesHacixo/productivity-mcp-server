# Secure Database Architecture

## ⚠️ Security Concerns

You're absolutely right to question storing OAuth identifiers as plaintext foreign keys. Let's design this properly.

## Current Architecture Issues

### Problem 1: Using External Identifiers as Foreign Keys
- ❌ Using `openId` (OAuth identifier) directly as `user_id` in Supabase
- ❌ No referential integrity
- ❌ Potential for identifier collisions
- ❌ Harder to maintain

### Problem 2: Dual User Systems
- MySQL has users table with `id` (int) and `openId` (string)
- Supabase expects `user_id UUID` referencing `auth.users`
- No connection between them

## ✅ Secure Architecture Options

### Option A: Use MySQL User ID (Recommended)

**Architecture:**
```
OAuth → openId (string: "user_abc123")
  ↓
Node.js Server → MySQL users table
  - id: 42 (internal, auto-increment)
  - openId: "user_abc123" (unique, indexed)
  ↓
tRPC Context → ctx.user.id (42)
  ↓
Go MCP Server → Receives user_id: 42
  ↓
Supabase → user_id: TEXT "42" or INTEGER
```

**Implementation:**
1. Keep MySQL for user management
2. Pass MySQL `user.id` (int) to Go server
3. Change Supabase schema to use `INTEGER` or `TEXT` for `user_id`
4. Create mapping table if needed: `user_id INT` → `supabase_user_id UUID`

**Security:**
- ✅ Internal IDs (not external identifiers)
- ✅ Referential integrity possible
- ✅ Can add constraints and indexes
- ✅ OAuth `openId` stays in MySQL only

### Option B: Use Supabase Auth Properly

**Architecture:**
```
OAuth → openId
  ↓
Node.js Server → Create/Get Supabase Auth User
  - Maps openId → Supabase auth.users UUID
  ↓
Store mapping: openId → supabase_user_id
  ↓
Go MCP Server → Uses Supabase auth.users UUID
  ↓
Supabase → user_id UUID REFERENCES auth.users(id)
```

**Implementation:**
1. Integrate Supabase Auth in Node.js server
2. Create Supabase user on first OAuth login
3. Store mapping: `openId` → `supabase_user_id`
4. Go server uses Supabase Auth UUIDs

**Security:**
- ✅ Uses Supabase Auth (proper auth system)
- ✅ UUIDs (not guessable)
- ✅ Full referential integrity
- ✅ RLS policies work correctly

### Option C: Hybrid with Mapping Table

**Architecture:**
```
MySQL users table:
  - id: 42 (primary key)
  - openId: "user_abc123" (unique)

Supabase user_mappings table:
  - mysql_user_id: 42 (references MySQL)
  - supabase_user_id: UUID (references auth.users)

Supabase tasks/goals:
  - user_id: UUID (references auth.users)
```

**Implementation:**
1. Keep MySQL for Node.js user management
2. Create Supabase Auth user on first login
3. Store mapping in Supabase
4. Go server looks up UUID from mapping

**Security:**
- ✅ Proper foreign keys
- ✅ Separation of concerns
- ✅ Can migrate systems independently

## 🎯 Recommended: Option A (Simplest & Secure)

For your current setup, **Option A** is best:

1. **Keep MySQL** for Node.js user management (already exists)
2. **Use MySQL user.id** (internal integer) as the identifier
3. **Change Supabase** to accept `INTEGER` or `TEXT` for `user_id`
4. **Never expose** `openId` in API responses or logs

### Migration Steps:

```sql
-- Supabase migration
ALTER TABLE tasks ALTER COLUMN user_id TYPE INTEGER;
ALTER TABLE goals ALTER COLUMN user_id TYPE INTEGER;
-- Remove foreign key to auth.users (we're using MySQL IDs)
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_user_id_fkey;
ALTER TABLE goals DROP CONSTRAINT IF EXISTS goals_user_id_fkey;
-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_tasks_user_id_int ON tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_goals_user_id_int ON goals(user_id);
```

### Code Changes:

**Node.js tRPC Router:**
```typescript
function getUserId(ctx: any): string {
  if (!ctx.user) {
    throw new Error("Authentication required");
  }
  // Use MySQL user.id, not openId
  return ctx.user.id.toString(); // Convert int to string
}
```

**Go MCP Server:**
```go
// Accept user_id as string (represents MySQL user.id)
userID := getUserID(c) // "42" (MySQL user ID)
```

## 🔒 Security Best Practices

1. **Never log `openId`** in production
2. **Use internal IDs** for foreign keys
3. **Validate user ownership** in RLS policies
4. **Sanitize all inputs** before database queries
5. **Use parameterized queries** (already done in Go code)

## 📊 Data Flow (Secure)

```
User Login
  ↓
OAuth Provider → Returns openId: "user_abc123"
  ↓
Node.js Server → MySQL Query
  SELECT id FROM users WHERE openId = 'user_abc123'
  Returns: id = 42
  ↓
Session Created → Stores MySQL user.id (42)
  ↓
API Request → ctx.user.id = 42
  ↓
tRPC Router → Passes "42" to Go server
  ↓
Go MCP Server → Uses "42" as user_id
  ↓
Supabase → Stores task with user_id = 42
  ↓
RLS Policy → Checks: user_id = 42 matches authenticated user
```

## ✅ Benefits

- ✅ **Security**: Internal IDs, not external identifiers
- ✅ **Performance**: Integer indexes are fast
- ✅ **Integrity**: Can add constraints if needed
- ✅ **Privacy**: `openId` never leaves MySQL
- ✅ **Flexibility**: Can migrate to Supabase Auth later
