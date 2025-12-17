# Missing Integrations & Issues Found

## ✅ What EXISTS

### 1. Auth Flow ✅
- **OAuth system**: Fully implemented with Manus OAuth
- **Auth hooks**: `useAuth()` hook works
- **Session management**: Cookie-based (web) and token-based (native)
- **User storage**: SecureStore (native) and localStorage (web)

### 2. AsyncStorage ✅
- **Storage hooks**: `useTasks()`, `useGoals()` use AsyncStorage
- **Local persistence**: Works for offline mode
- **Storage keys**: Properly defined in `lib/types.ts`

### 3. Database Schema ✅
- **Migration file**: `supabase/migrations/001_init_schema.sql` exists
- **Tables defined**: tasks, goals, subtasks, milestones, etc.

## ❌ What's MISSING or BROKEN

### 1. Auth Not Connected to tRPC ⚠️ CRITICAL

**Problem:**
```typescript
// server/routers/task.ts line 10-14
function getUserId(ctx: any): string {
  // TODO: Extract from auth context when auth is implemented
  // For now, use a default or extract from headers
  return ctx.user?.id || ctx.req.headers["x-user-id"] || "default-user";
}
```

**Issue:**
- Auth system exists but isn't integrated with tRPC context
- All API calls use `"default-user"` instead of real user ID
- User authentication is not passed to MCP server

**Fix Needed:**
- Connect `authenticateRequest()` from `server/_core/sdk.ts` to tRPC context
- Extract user `openId` from authenticated session
- Pass `openId` as `user_id` to MCP server

### 2. Database Schema Mismatch ⚠️ CRITICAL

**Problem:**
- **Migration schema**: `user_id UUID NOT NULL REFERENCES auth.users(id)`
- **Go server expects**: `user_id TEXT` (string)
- **Webapp uses**: `openId` (string from OAuth, not Supabase auth UUID)

**Issue:**
- Go MCP server sends `user_id` as TEXT/string
- Supabase table expects UUID that references `auth.users`
- These don't match!

**Options to Fix:**
1. **Change Go server** to use Supabase Auth UUIDs (requires auth integration)
2. **Change migration** to use `TEXT` instead of `UUID` (simpler, but loses referential integrity)
3. **Add mapping table** between `openId` and Supabase `auth.users` UUID

### 3. User ID Not Passed from Frontend ⚠️

**Problem:**
```typescript
// hooks/use-tasks-api.ts
export function useTasksAPI(userId?: string) {
  const { data: tasks } = trpc.task.list.useQuery(
    { userId: userId || "default-user" }, // ❌ Hardcoded fallback
    { enabled: !!userId }
  );
}
```

**Issue:**
- Frontend hooks don't get user ID from auth
- Falls back to `"default-user"`
- Should use `useAuth()` to get current user's `openId`

**Fix Needed:**
```typescript
const { user } = useAuth();
const userId = user?.openId || null;
const { data: tasks } = trpc.task.list.useQuery(
  { userId }, // ✅ Use real user ID
  { enabled: !!userId }
);
```

### 4. RLS Policies Not Configured ⚠️

**Problem:**
- Migration enables RLS but doesn't create policies
- Go server uses anon key (not service role)
- Without policies, all queries will fail with RLS

**Fix Needed:**
- Create RLS policies that allow operations based on `user_id`
- OR disable RLS for development (not recommended for production)

## 🔧 Required Fixes

### Priority 1: Connect Auth to tRPC

1. Update tRPC context to authenticate requests:
```typescript
// server/_core/context.ts
export async function createContext({ req, res }: CreateExpressContextOptions) {
  try {
    const user = await sdk.authenticateRequest(req);
    return { user, req, res };
  } catch {
    return { user: null, req, res };
  }
}
```

2. Update routers to use authenticated user:
```typescript
// server/routers/task.ts
function getUserId(ctx: any): string {
  if (!ctx.user) {
    throw new Error("Authentication required");
  }
  return ctx.user.openId; // ✅ Use OAuth openId
}
```

3. Make procedures protected:
```typescript
import { protectedProcedure } from "../_core/trpc"; // Need to create this

export const taskRouter = router({
  list: protectedProcedure.query(async ({ ctx }) => {
    const userId = ctx.user.openId;
    // ...
  }),
});
```

### Priority 2: Fix Database Schema

**Option A: Change to TEXT (Simplest)**
```sql
-- New migration
ALTER TABLE tasks ALTER COLUMN user_id TYPE TEXT;
ALTER TABLE goals ALTER COLUMN user_id TYPE TEXT;
-- Remove foreign key constraints
ALTER TABLE tasks DROP CONSTRAINT tasks_user_id_fkey;
ALTER TABLE goals DROP CONSTRAINT goals_user_id_fkey;
```

**Option B: Use Supabase Auth (More Complex)**
- Integrate Supabase Auth in Go server
- Map OAuth `openId` to Supabase `auth.users` UUID
- Requires additional auth layer

### Priority 3: Update Frontend Hooks

```typescript
// hooks/use-tasks-api.ts
export function useTasksAPI() {
  const { user } = useAuth();
  const userId = user?.openId;
  
  const { data: tasks } = trpc.task.list.useQuery(
    undefined, // Let server get from context
    { enabled: !!userId }
  );
  // ...
}
```

### Priority 4: Add RLS Policies

```sql
-- Allow users to access their own tasks
CREATE POLICY "Users can view own tasks"
  ON tasks FOR SELECT
  USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own tasks"
  ON tasks FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text);

-- Similar for goals, etc.
```

## 📋 Summary

| Component | Status | Issue |
|-----------|--------|-------|
| Auth System | ✅ Exists | ❌ Not connected to tRPC |
| AsyncStorage | ✅ Exists | ✅ Works |
| Database Schema | ⚠️ Exists | ❌ Type mismatch (UUID vs TEXT) |
| User ID Passing | ❌ Missing | Uses "default-user" |
| RLS Policies | ❌ Missing | Will block all queries |

## 🎯 Next Steps

1. **Fix auth integration** - Connect OAuth to tRPC context
2. **Fix database schema** - Choose UUID or TEXT approach
3. **Update frontend hooks** - Use real user ID from auth
4. **Add RLS policies** - Or disable for development
5. **Test end-to-end** - Verify user can create tasks with their own ID
