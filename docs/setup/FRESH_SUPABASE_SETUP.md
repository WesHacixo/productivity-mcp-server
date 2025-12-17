# Fresh Supabase Setup - Clean Start 🚀

Let's start fresh with a new Supabase project. This is simpler and cleaner.

## Step 1: Create New Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Click **"New Project"**
4. Fill in:
   - **Name**: `productivity-tool` (or whatever you want)
   - **Database Password**: Create a strong password (save it!)
   - **Region**: Choose closest to you
5. Click **"Create new project"**
6. Wait 2-3 minutes for it to initialize

## Step 2: Get Your Credentials

1. Go to **Settings → API**
2. Copy these two values:
   - **Project URL** → This is your `SUPABASE_URL`
   - **anon public** key → This is your `SUPABASE_ANON_KEY`

## Step 3: Run the Clean Schema

1. Go to **SQL Editor** in Supabase dashboard
2. Click **"New Query"**
3. Copy the **entire contents** of `productivity_tool_app/supabase/migrations/001_clean_schema.sql`
4. Paste into the SQL editor
5. Click **"Run"** (or press Cmd/Ctrl + Enter)

That's it! ✅

## Step 4: Set Environment Variables

### For Go MCP Server (Railway):
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### For Node.js Server (local):
Add to your `.env` file:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

## What's Different (Why This is Better)

✅ **Uses INTEGER user_id from the start** - No migration needed
✅ **Matches MySQL user.id** - Direct compatibility
✅ **Simple RLS policies** - Can tighten later
✅ **Clean schema** - No legacy UUID mess

## That's It!

Your Supabase is ready. The Go server will work immediately with INTEGER user_id.

No migrations, no UUID conversion, no headaches. Just works. 🎉
