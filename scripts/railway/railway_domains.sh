#!/bin/bash
# Quick script to get Railway domains - accepts API key as argument or env var

API_KEY="${1:-$RAILWAY_API}"

if [ -z "$API_KEY" ]; then
    echo "Usage: $0 [RAILWAY_API_TOKEN]"
    echo "   Or: export RAILWAY_API='token' && $0"
    exit 1
fi

PROJECT_ID="6e921b3a-2d3e-4aa8-af94-cfa4f48cc5a5"

echo "🔍 Fetching Railway service domains..."
echo ""

QUERY='{
  "query": "query { project(id: \"'$PROJECT_ID'\") { services { id name domains { domain } } } }"
}'

RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$QUERY" \
  https://backboard.railway.app/graphql/v2)

if echo "$RESPONSE" | grep -q '"errors"'; then
    echo "❌ Error:"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    exit 1
fi

# Extract service domains
if command -v jq >/dev/null 2>&1; then
    echo "$RESPONSE" | jq -r '.data.project.services[] | "\(.name): \(if .domains | length > 0 then .domains[].domain else "No domain (unexposed)" end)"'
    
    MCP_DOMAIN=$(echo "$RESPONSE" | jq -r '.data.project.services[] | select(.name == "productivity-mcp-server") | .domains[0].domain // empty')
    
    if [ -n "$MCP_DOMAIN" ]; then
        echo ""
        echo "✅ MCP Server URL: https://$MCP_DOMAIN"
    else
        echo ""
        echo "⚠️  productivity-mcp-server has no public domain"
    fi
else
    echo "$RESPONSE" | python3 -m json.tool
    echo ""
    echo "💡 Install 'jq' for better output: brew install jq"
fi
