# Supabase Connectivity Setup

## ✅ Code Status
The Supabase client is properly implemented and will connect via HTTP REST API.

## 🔑 Required Environment Variables

Your Railway service **MUST** have these environment variables set:

### Required (Service won't start without these):
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### Optional (for AI features):
```bash
CLAUDE_API_KEY=your-claude-api-key
```

## 📋 How to Set in Railway

1. **Go to Railway Dashboard:**
   - Navigate to: https://railway.com/project/6e921b3a-2d3e-4aa8-af94-cfa4f48cc5a5
   - Click on **"productivity-mcp-server"** service
   - Go to **"Variables"** tab

2. **Add Environment Variables:**
   - Click **"+ New Variable"**
   - Add each variable:
     - `SUPABASE_URL` = `https://your-project.supabase.co`
     - `SUPABASE_ANON_KEY` = `your-anon-key`
     - `CLAUDE_API_KEY` = `your-claude-key` (optional)

3. **Get Your Supabase Credentials:**
   - Go to: https://supabase.com/dashboard
   - Select your project
   - Go to **Settings** → **API**
   - Copy:
     - **Project URL** → Use as `SUPABASE_URL`
     - **anon/public key** → Use as `SUPABASE_ANON_KEY`

## ⚠️ Important Notes

### URL Format
The code automatically appends `/rest/v1/` to your Supabase URL, so:
- ✅ Correct: `https://your-project.supabase.co`
- ❌ Wrong: `https://your-project.supabase.co/rest/v1` (don't include this)

### Anon Key vs Service Role Key
- Use **anon/public key** for `SUPABASE_ANON_KEY`
- This is safe for client-side operations
- Row Level Security (RLS) policies will apply

### Service Startup
If `SUPABASE_URL` or `SUPABASE_ANON_KEY` are missing, the service will:
- ❌ **Fail to start** with error: `Missing SUPABASE_URL or SUPABASE_ANON_KEY environment variables`
- Check Railway logs to see this error

## 🧪 Testing Supabase Connection

Once deployed, test the connection:

```bash
# Test health (doesn't require Supabase)
curl https://productivity-mcp-server-production.up.railway.app/health

# Test task creation (requires Supabase)
curl -X POST https://productivity-mcp-server-production.up.railway.app/api/tasks \
  -H "Content-Type: application/json" \
  -H "X-User-ID: test-user-123" \
  -d '{
    "title": "Test Task",
    "description": "Testing Supabase connection",
    "dueDate": "2024-12-31T23:59:59Z",
    "priority": 3
  }'
```

## 🔍 Troubleshooting

### Service returns 502
- Check Railway logs for: `Missing SUPABASE_URL or SUPABASE_ANON_KEY`
- Verify variables are set in Railway dashboard
- Make sure variable names are exact (case-sensitive)

### 401 Unauthorized from Supabase
- Verify `SUPABASE_ANON_KEY` is correct
- Check if you're using the anon key (not service role key)
- Verify RLS policies allow the operation

### 404 Not Found from Supabase
- Verify `SUPABASE_URL` is correct (no trailing `/rest/v1`)
- Check that tables `tasks` and `goals` exist in your Supabase project
- Verify the project is active

### Connection Timeout
- Check if Supabase project is paused (free tier pauses after inactivity)
- Verify network connectivity from Railway to Supabase
- Check Supabase dashboard for any service issues

## 📊 Database Schema Requirements

Your Supabase database needs these tables:

### `tasks` table:
```sql
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  priority INTEGER DEFAULT 3,
  due_date TIMESTAMPTZ,
  estimated_duration INTEGER,
  category TEXT,
  completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  recurring_frequency TEXT,
  recurring_interval INTEGER,
  recurring_end_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

### `goals` table:
```sql
CREATE TABLE goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMPTZ NOT NULL,
  target_date TIMESTAMPTZ NOT NULL,
  progress NUMERIC DEFAULT 0,
  archived BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

## ✅ Verification Checklist

Before deploying, ensure:
- [ ] `SUPABASE_URL` is set in Railway
- [ ] `SUPABASE_ANON_KEY` is set in Railway
- [ ] Supabase project is active (not paused)
- [ ] `tasks` table exists with correct schema
- [ ] `goals` table exists with correct schema
- [ ] RLS policies allow operations (or disabled for testing)
- [ ] Service can reach Supabase (no firewall blocking)
