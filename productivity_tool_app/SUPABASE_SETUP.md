# Supabase Setup Guide

This guide walks you through setting up Supabase for the Productivity Tool App.

## Step 1: Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in with your account
3. Click "New Project"
4. Fill in the project details:
   - **Name**: `productivity-tool` (or your preferred name)
   - **Database Password**: Create a strong password
   - **Region**: Choose the region closest to your users
5. Click "Create new project" and wait for it to initialize (5-10 minutes)

## Step 2: Get Your Credentials

1. Once your project is ready, go to **Settings → API**
2. Copy the following values:
   - **Project URL**: This is your `SUPABASE_URL`
   - **anon public**: This is your `SUPABASE_ANON_KEY`

## Step 3: Run Database Migrations

1. Go to the **SQL Editor** in your Supabase dashboard
2. Click "New Query"
3. Copy the entire contents of `supabase/migrations/001_init_schema.sql`
4. Paste it into the SQL editor
5. Click "Run" to execute the migration

This will create all necessary tables with proper indexes and Row Level Security (RLS) policies.

## Step 4: Enable Real-time

1. In your Supabase dashboard, go to **Database → Replication**
2. Enable replication for the following tables:
   - `tasks`
   - `goals`
   - `time_blocks`
   - `inbox_files`
3. This allows the app to receive real-time updates when data changes

## Step 5: Configure Authentication

1. Go to **Authentication → Providers**
2. Enable "Email" provider (should be enabled by default)
3. (Optional) Enable OAuth providers like Google, GitHub, etc.

## Step 6: Set Environment Variables

The app already has `SUPABASE_URL` and `SUPABASE_ANON_KEY` set from your input. These are automatically injected into the app.

## Step 7: Test the Connection

Run the test suite to verify your Supabase setup:

```bash
pnpm test __tests__/supabase.test.ts
```

All tests should pass, confirming your credentials are valid and the connection works.

## Database Schema Overview

### Core Tables

- **user_profiles**: Extended user information (display name, theme, settings)
- **tasks**: Task records with priority, due date, category, and recurrence
- **subtasks**: Subtasks linked to parent tasks
- **goals**: Long-term goals with target dates and progress tracking
- **milestones**: Milestones within goals
- **time_blocks**: Time blocks scheduled for tasks
- **file_attachments**: Files attached to tasks or goals
- **inbox_files**: Files received from share sheet awaiting processing

### Security

All tables have Row Level Security (RLS) enabled. Users can only access their own data through the following policies:

- Users can only view/edit/delete their own records
- Authenticated users can create new records
- All operations are scoped to `auth.uid()`

## Real-time Subscriptions

The app uses Supabase real-time subscriptions to keep data in sync across devices. Changes made on one device are automatically reflected on other devices within seconds.

Subscriptions are set up for:
- Task changes (create, update, delete)
- Goal changes (create, update, delete)
- Time block changes (create, update, delete)

## Offline Support

The app uses a hybrid approach:
1. **Online**: Data syncs with Supabase in real-time
2. **Offline**: Changes are queued locally and synced when reconnected

## Troubleshooting

### "Invalid credentials" error
- Double-check your `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- Ensure they're from the same Supabase project
- Verify the project is active (not paused)

### Real-time updates not working
- Ensure replication is enabled for the table in **Database → Replication**
- Check that RLS policies allow the operation
- Verify network connectivity

### Permission denied errors
- Check that RLS policies are correctly configured
- Ensure you're authenticated before performing operations
- Verify the user ID matches the record's `user_id`

## Next Steps

Once Supabase is set up:
1. The app will automatically sync tasks, goals, and time blocks to the cloud
2. Users can sign up and log in with their email
3. Data will be accessible across multiple devices
4. Real-time updates will keep all devices in sync

For more information, visit the [Supabase documentation](https://supabase.com/docs).
