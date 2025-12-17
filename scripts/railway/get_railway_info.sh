#!/bin/bash
# Script to get Railway service URL using Railway API

set -e

# Try to get Railway API key from various sources
RAILWAY_API_KEY=""

# Method 1: Command line argument
if [ -n "$1" ]; then
    RAILWAY_API_KEY="$1"
    echo "✅ Using API key from command line argument"
# Method 2: Environment variables (check multiple names)
elif [ -n "$RAILWAY_API" ]; then
    RAILWAY_API_KEY="$RAILWAY_API"
    echo "✅ Using RAILWAY_API from environment"
elif [ -n "$RAILWAY_API_KEY" ]; then
    echo "✅ Using RAILWAY_API_KEY from environment"
elif [ -n "$RAILWAY_TOKEN" ]; then
    RAILWAY_API_KEY="$RAILWAY_TOKEN"
    echo "✅ Using RAILWAY_TOKEN from environment"
# Method 2: macOS Keychain (check by account "DAE" first, then service names)
elif command -v security >/dev/null 2>&1; then
    # Try to find by account "DAE" (as user added it with -a "DAE")
    # First try without service name (finds first match)
    RAILWAY_API_KEY=$(security find-generic-password -a "DAE" -w 2>/dev/null || echo "")
    
    # If that fails, try with the UUID service name we found
    if [ -z "$RAILWAY_API_KEY" ]; then
        RAILWAY_API_KEY=$(security find-generic-password -a "DAE" -s "3892e3a9-d6e1-463c-9a8f-3462cd0c9e00" -w 2>/dev/null || echo "")
    fi
    
    if [ -n "$RAILWAY_API_KEY" ]; then
        echo "✅ Found API key in keychain (account: DAE)"
    else
        # Fallback: try common service names
        for key_name in "RAILWAY_API" "railway-api-key" "railway-token" "Railway API Key" "railway"; do
            RAILWAY_API_KEY=$(security find-generic-password -s "$key_name" -w 2>/dev/null || echo "")
            if [ -n "$RAILWAY_API_KEY" ]; then
                echo "✅ Found API key in keychain: $key_name"
                break
            fi
        done
    fi
fi

if [ -z "$RAILWAY_API_KEY" ]; then
    echo "❌ Railway API key not found!"
    echo ""
    echo "Usage:"
    echo "  ./scripts/get_railway_info.sh [API_TOKEN]"
    echo ""
    echo "Or set one of these environment variables:"
    echo "  export RAILWAY_API='your-token'"
    echo "  export RAILWAY_API_KEY='your-token'"
    echo "  export RAILWAY_TOKEN='your-token'"
    echo ""
    echo "Or add to macOS Keychain with name: 'RAILWAY_API'"
    echo ""
    echo "To get your API token:"
    echo "  1. Go to: https://railway.com/account/tokens"
    echo "  2. Create a new token"
    echo "  3. Copy it and either:"
    echo "     - Pass as argument: ./scripts/get_railway_info.sh YOUR_TOKEN"
    echo "     - Set env var: export RAILWAY_API='YOUR_TOKEN'"
    echo "     - Add to keychain: security add-generic-password -s 'RAILWAY_API' -w 'YOUR_TOKEN'"
    exit 1
fi

PROJECT_ID="6e921b3a-2d3e-4aa8-af94-cfa4f48cc5a5"
ENVIRONMENT_ID="494b4e30-a755-4953-9de9-3b569e038246"

echo "🔍 Fetching Railway service information..."
echo ""

# Query Railway GraphQL API for service domains
QUERY='{
  "query": "query { project(id: \"'$PROJECT_ID'\") { services { id name domains { domain } } } }"
}'

RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $RAILWAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$QUERY" \
  https://backboard.railway.app/graphql/v2)

# Check for errors
if echo "$RESPONSE" | grep -q '"errors"'; then
    echo "❌ API Error:"
    echo "$RESPONSE" | jq -r '.errors[0].message' 2>/dev/null || echo "$RESPONSE"
    exit 1
fi

# Extract service information
echo "📋 Service Information:"
echo ""

# Check if jq is available
if command -v jq >/dev/null 2>&1; then
    echo "$RESPONSE" | jq -r '.data.project.services[] | "Service: \(.name)\n  ID: \(.id)\n  Domains: \(.domains | if length > 0 then .[].domain else "No domains (unexposed)" end)\n"'
    
    # Get the productivity-mcp-server service
    SERVICE_DOMAIN=$(echo "$RESPONSE" | jq -r '.data.project.services[] | select(.name == "productivity-mcp-server") | .domains[0].domain // empty')
    
    if [ -n "$SERVICE_DOMAIN" ]; then
        echo ""
        echo "✅ Your MCP Server URL:"
        echo "   https://$SERVICE_DOMAIN"
        echo ""
        echo "Test it:"
        echo "   curl https://$SERVICE_DOMAIN/health"
    else
        echo ""
        echo "⚠️  Service 'productivity-mcp-server' has no public domain"
        echo ""
        echo "To generate a domain:"
        echo "  1. Go to Railway dashboard"
        echo "  2. Click on 'productivity-mcp-server' service"
        echo "  3. Click 'Generate Domain' or 'Expose Service'"
    fi
else
    echo "$RESPONSE"
    echo ""
    echo "💡 Install 'jq' for better output: brew install jq"
fi
