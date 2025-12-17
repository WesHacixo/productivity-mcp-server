# Supabase CLI Setup Guide

## Quick Start

### 1. Login to Supabase CLI

```bash
supabase login
```

This will open your browser for authentication. After logging in, you're ready to proceed.

### 2. Run the Setup Script

```bash
./scripts/setup_supabase_cli.sh
```

The script will:
- Check if you're logged in
- Show your existing projects
- Create a new project (or link to existing)
- Link the project locally
- Get credentials
- Run the migration

## Manual Setup (Alternative)

If you prefer to do it manually:

### Step 1: Login
```bash
supabase login
```

### Step 2: Create New Project
```bash
supabase projects create productivity-tool \
  --db-password "your-strong-password" \
  --region us-east-1
```

This will output a project reference (ref) like `abcdefghijklmnop`.

### Step 3: Link Project Locally
```bash
cd productivity_tool_app
supabase link --project-ref abcdefghijklmnop
cd ..
```

### Step 4: Run Migration
```bash
cd productivity_tool_app
supabase db push
cd ..
```

### Step 5: Get Credentials
```bash
cd productivity_tool_app
supabase status --output env
cd ..
```

This will show:
```
SUPABASE_URL=https://abcdefghijklmnop.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Using Existing Project

If you already have a Supabase project:

```bash
cd productivity_tool_app
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
supabase status --output env
cd ..
```

## Environment Variables

After setup, add these to Railway:

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## Troubleshooting

### "Access token not provided"
Run `supabase login` first.

### "Project not found"
Make sure you're using the correct project reference (ref), not the project ID.

### Migration fails
Check that you're in the `productivity_tool_app` directory when running `supabase db push`.

### Get project reference
```bash
supabase projects list
```

This shows all your projects with their refs.
