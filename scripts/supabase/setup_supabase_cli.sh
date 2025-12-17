#!/bin/bash
# Supabase CLI Setup Script
# This script helps you set up a new Supabase project using the CLI

set -e

echo "🚀 Supabase CLI Setup"
echo "===================="
echo ""

# Check if logged in
echo "📋 Checking Supabase login status..."
if ! supabase projects list &>/dev/null; then
    echo "❌ Not logged in. Please log in first:"
    echo ""
    echo "   supabase login"
    echo ""
    echo "This will open a browser for authentication."
    exit 1
fi

echo "✅ Already logged in!"
echo ""

# Show existing projects
echo "📦 Your existing projects:"
supabase projects list
echo ""

# Ask if they want to create a new project or use existing
read -p "Create a new project? (y/n): " create_new

if [[ "$create_new" == "y" || "$create_new" == "Y" ]]; then
    read -p "Project name (default: productivity-tool): " project_name
    project_name=${project_name:-productivity-tool}
    
    read -p "Database password (min 8 chars): " db_password
    
    read -p "Region (default: us-east-1): " region
    region=${region:-us-east-1}
    
    echo ""
    echo "🔄 Creating new Supabase project: $project_name"
    echo "This may take a few minutes..."
    
    # Create project
    PROJECT_OUTPUT=$(supabase projects create "$project_name" --db-password "$db_password" --region "$region" --output json)
    
    PROJECT_ID=$(echo "$PROJECT_OUTPUT" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
    PROJECT_REF=$(echo "$PROJECT_OUTPUT" | grep -o '"ref":"[^"]*' | cut -d'"' -f4)
    
    if [ -z "$PROJECT_ID" ]; then
        echo "❌ Failed to create project. Please check the output above."
        exit 1
    fi
    
    echo "✅ Project created!"
    echo "   Project ID: $PROJECT_ID"
    echo "   Project Ref: $PROJECT_REF"
    echo ""
    
    # Wait for project to be ready
    echo "⏳ Waiting for project to be ready..."
    sleep 10
    
    # Link the project
    echo "🔗 Linking project locally..."
    cd productivity_tool_app
    supabase link --project-ref "$PROJECT_REF"
    cd ..
    
else
    # Use existing project
    echo ""
    read -p "Enter project reference (ref): " project_ref
    
    echo "🔗 Linking project locally..."
    cd productivity_tool_app
    supabase link --project-ref "$project_ref"
    cd ..
fi

echo ""
echo "📝 Getting project credentials..."
cd productivity_tool_app

# Get project URL and anon key
PROJECT_URL=$(supabase status --output env | grep SUPABASE_URL | cut -d'=' -f2-)
ANON_KEY=$(supabase status --output env | grep SUPABASE_ANON_KEY | cut -d'=' -f2-)

if [ -z "$PROJECT_URL" ] || [ -z "$ANON_KEY" ]; then
    echo "⚠️  Could not automatically get credentials."
    echo "   Please get them from: https://supabase.com/dashboard/project/$project_ref/settings/api"
else
    echo "✅ Credentials retrieved!"
    echo ""
    echo "📋 Add these to your environment:"
    echo ""
    echo "SUPABASE_URL=$PROJECT_URL"
    echo "SUPABASE_ANON_KEY=$ANON_KEY"
    echo ""
fi

cd ..

echo "🔄 Running migration..."
cd productivity_tool_app
supabase db push
cd ..

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Add SUPABASE_URL and SUPABASE_ANON_KEY to Railway"
echo "2. Add DATABASE_URL for MySQL (Node.js server)"
echo "3. Test the integration!"
