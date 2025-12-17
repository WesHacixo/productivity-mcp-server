#!/bin/bash
# Check if Supabase environment variables are configured
# Usage: ./scripts/check_supabase_config.sh

echo "🔍 Checking Supabase Configuration"
echo "=================================="
echo ""

# Check local .env file
if [ -f ".env" ]; then
    echo "📄 Found .env file:"
    if grep -q "SUPABASE_URL" .env; then
        SUPABASE_URL=$(grep "SUPABASE_URL" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        echo "  ✅ SUPABASE_URL is set: ${SUPABASE_URL:0:30}..."
    else
        echo "  ❌ SUPABASE_URL not found in .env"
    fi
    
    if grep -q "SUPABASE_ANON_KEY" .env; then
        SUPABASE_KEY=$(grep "SUPABASE_ANON_KEY" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        echo "  ✅ SUPABASE_ANON_KEY is set: ${SUPABASE_KEY:0:20}..."
    else
        echo "  ❌ SUPABASE_ANON_KEY not found in .env"
    fi
else
    echo "📄 No .env file found (this is okay for Railway deployment)"
fi

echo ""
echo "🌐 Railway Environment Variables:"
echo "  Go to: Railway Dashboard → Your Service → Variables"
echo "  Required:"
echo "    - SUPABASE_URL"
echo "    - SUPABASE_ANON_KEY"
echo "  Optional:"
echo "    - CLAUDE_API_KEY"
echo ""

echo "📋 To get your Supabase credentials:"
echo "  1. Go to: https://supabase.com/dashboard"
echo "  2. Select your project"
echo "  3. Go to Settings → API"
echo "  4. Copy:"
echo "     - Project URL → SUPABASE_URL"
echo "     - anon/public key → SUPABASE_ANON_KEY"
echo ""

echo "⚠️  Important:"
echo "  - SUPABASE_URL should NOT include /rest/v1 (code adds it automatically)"
echo "  - Use the anon/public key, not service role key"
echo "  - Service will fail to start if these are missing"
echo ""
