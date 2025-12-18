#!/bin/bash

# Quick Deployment Script for OAuth 2.1 Production Release

set -e

echo "🚀 Starting OAuth 2.1 Production Deployment"
echo "============================================"
echo ""

# Step 1: Verify build
echo "📦 Step 1: Verifying build..."
if ! go build .; then
    echo "❌ Build failed! Fix errors before deploying."
    exit 1
fi
echo "✅ Build successful"
echo ""

# Step 2: Check git status
echo "📋 Step 2: Checking git status..."
if [ -z "$(git status --porcelain)" ]; then
    echo "⚠️  No changes to commit. Everything is already committed."
else
    echo "📝 Changes detected:"
    git status --short
    echo ""
    
    # Step 3: Add all changes
    echo "📦 Step 3: Staging changes..."
    git add .
    echo "✅ Changes staged"
    echo ""
    
    # Step 4: Commit
    echo "💾 Step 4: Committing changes..."
    git commit -m "feat: OAuth 2.1 implementation with PKCE and Claude Desktop support

- Implement OAuth 2.1 authorization code flow with PKCE (S256)
- Add /authorize and /oauth/authorize endpoints
- Add OAuth discovery endpoint (/.well-known/oauth-authorization-server)
- Support Claude redirect URIs (claude.ai/api/mcp/auth_callback, claude://oauth-callback)
- Implement proper error redirects per OAuth 2.1 spec
- Add default OAuth clients (claude-desktop, mcp_client)
- Add auth code storage with expiration and one-time use
- Add debug instrumentation for troubleshooting
- Support custom URL schemes for native app redirects"
    echo "✅ Changes committed"
    echo ""
fi

# Step 5: Push to Railway
echo "🚀 Step 5: Pushing to Railway..."
echo "This will trigger automatic deployment..."
echo ""

# Detect branch name
BRANCH=$(git branch --show-current)
if [ -z "$BRANCH" ]; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

echo "Pushing to: origin/$BRANCH"
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push origin "$BRANCH"
    echo ""
    echo "✅ Code pushed to Railway"
    echo ""
    echo "⏳ Waiting for deployment..."
    echo "Railway will:"
    echo "  1. Detect the push"
    echo "  2. Build the Go binary"
    echo "  3. Deploy to production"
    echo "  4. Run health checks"
    echo ""
    echo "⏱️  This typically takes 2-3 minutes"
    echo ""
    echo "📊 Monitor deployment:"
    echo "  Railway Dashboard → Your Service → Deployments"
    echo ""
    echo "🧪 Test after deployment:"
    echo "  curl https://productivity-mcp-server-production.up.railway.app/.well-known/oauth-authorization-server"
    echo ""
    echo "🎉 Deployment initiated!"
else
    echo "❌ Deployment cancelled"
    exit 1
fi
