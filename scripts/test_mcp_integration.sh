#!/bin/bash
# Test MCP Server integration with webapp
# Usage: ./scripts/test_mcp_integration.sh [RAILWAY_URL]

MCP_URL="${1:-${MCP_SERVER_URL:-http://localhost:8080}}"

echo "🧪 Testing MCP Server Integration"
echo "=================================="
echo ""
echo "MCP Server URL: $MCP_URL"
echo ""

# Test 1: Health Check
echo "1️⃣  Testing Health Endpoint..."
HEALTH_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$MCP_URL/health")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
HEALTH_BODY=$(echo "$HEALTH_RESPONSE" | sed '/HTTP_CODE/d')

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Health check passed"
    echo "   Response: $HEALTH_BODY"
else
    echo "❌ Health check failed (HTTP $HTTP_CODE)"
    echo "   Response: $HEALTH_BODY"
    exit 1
fi

echo ""

# Test 2: MCP Initialize
echo "2️⃣  Testing MCP Initialize..."
INIT_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$MCP_URL/mcp/initialize" \
    -H "Content-Type: application/json" \
    -d '{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test-client","version":"1.0.0"}}')
HTTP_CODE=$(echo "$INIT_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
INIT_BODY=$(echo "$INIT_RESPONSE" | sed '/HTTP_CODE/d')

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ MCP Initialize passed"
    echo "   Response: $INIT_BODY"
else
    echo "❌ MCP Initialize failed (HTTP $HTTP_CODE)"
    echo "   Response: $INIT_BODY"
fi

echo ""

# Test 3: MCP List Tools
echo "3️⃣  Testing MCP List Tools..."
TOOLS_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$MCP_URL/mcp/list_tools")
HTTP_CODE=$(echo "$TOOLS_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
TOOLS_BODY=$(echo "$TOOLS_RESPONSE" | sed '/HTTP_CODE/d')

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ MCP List Tools passed"
    echo "   Response: $TOOLS_BODY"
else
    echo "❌ MCP List Tools failed (HTTP $HTTP_CODE)"
    echo "   Response: $TOOLS_BODY"
fi

echo ""

# Test 4: Tasks API
echo "4️⃣  Testing Tasks API..."
TASKS_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$MCP_URL/api/tasks/user/test-user")
HTTP_CODE=$(echo "$TASKS_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
TASKS_BODY=$(echo "$TASKS_RESPONSE" | sed '/HTTP_CODE/d')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
    echo "✅ Tasks API accessible (HTTP $HTTP_CODE)"
    if [ "$HTTP_CODE" = "200" ]; then
        echo "   Response: $TASKS_BODY"
    fi
else
    echo "❌ Tasks API failed (HTTP $HTTP_CODE)"
    echo "   Response: $TASKS_BODY"
fi

echo ""
echo "=================================="
echo "✅ Integration tests complete!"
echo ""
echo "Next steps:"
echo "1. Update webapp environment:"
echo "   export MCP_SERVER_URL=\"$MCP_URL\""
echo ""
echo "2. Or add to productivity_tool_app/.env:"
echo "   MCP_SERVER_URL=$MCP_URL"
echo ""
echo "3. Restart your webapp server to use the new URL"
