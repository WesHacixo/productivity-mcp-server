# Supabase CLI Quick Start 🚀

## Step 1: Login (Do this first!)

Open your terminal and run:

```bash
cd productivity_tool_app
supabase login
```

This will open your browser. After logging in, come back here.

## Step 2: Create New Project

After logging in, run:

```bash
supabase projects create productivity-tool \
  --db-password "YOUR_STRONG_PASSWORD_HERE" \
  --region us-east-1
```

**Important:** Replace `YOUR_STRONG_PASSWORD_HERE` with a strong password (save it!).

This will output something like:
```
Created project abcdefghijklmnop
```

Copy the project reference (the long string).

## Step 3: Link Project

```bash
supabase link --project-ref abcdefghijklmnop
```

Replace `abcdefghijklmnop` with your actual project reference.

## Step 4: Push Migration

```bash
supabase db push
```

This will run the clean schema migration.

## Step 5: Get Credentials

```bash
supabase status --output env
```

This will show:
```
SUPABASE_URL=https://abcdefghijklmnop.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Copy these values!

## Step 6: Add to Railway

Go to Railway dashboard → Your service → Variables tab → Add:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

## All-in-One Script (After Login)

If you want to do steps 2-5 in one go, you can use:

```bash
# After login, run this (replace PASSWORD and PROJECT_REF):
PROJECT_REF=$(supabase projects create productivity-tool --db-password "YOUR_PASSWORD" --region us-east-1 --output json | grep -o '"ref":"[^"]*' | cut -d'"' -f4)
supabase link --project-ref "$PROJECT_REF"
supabase db push
supabase status --output env
```

## Troubleshooting

### "Access token not provided"
Run `supabase login` first.

### "Project not found"
Make sure you're using the project reference (ref), not the project ID.

### See all your projects
```bash
supabase projects list
```
