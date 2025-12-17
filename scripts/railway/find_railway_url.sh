#!/bin/bash
# Script to help find and test Railway deployment URL

echo "🔍 Finding Railway Deployment URL"
echo "=================================="
echo ""
echo "To find your Railway service URL:"
echo ""
echo "1. Go to Railway Dashboard:"
echo "   https://railway.com/project/6e921b3a-2d3e-4aa8-af94-cfa4f48cc5a5"
echo ""
echo "2. Click on 'productivity-mcp-server' service"
echo ""
echo "3. Go to 'Settings' tab"
echo ""
echo "4. Look for 'Domains' section - your URL will be listed there"
echo "   Format: https://your-service-name.up.railway.app"
echo ""
echo "5. Or check the 'Deployments' tab for the generated URL"
echo ""
echo "Once you have the URL, test it with:"
echo ""
echo "  curl https://your-service-name.up.railway.app/health"
echo ""
echo "Expected response:"
echo '  {"status":"ok","service":"productivity-mcp-server"}'
echo ""

# If URL is provided as argument, test it
if [ -n "$1" ]; then
    URL="$1"
    echo "Testing URL: $URL"
    echo ""
    
    echo "Testing /health endpoint..."
    HEALTH_RESPONSE=$(curl -s "$URL/health")
    if [ $? -eq 0 ]; then
        echo "✅ Health check passed!"
        echo "Response: $HEALTH_RESPONSE"
    else
        echo "❌ Health check failed"
    fi
    
    echo ""
    echo "Testing /mcp/initialize endpoint..."
    INIT_RESPONSE=$(curl -s -X POST "$URL/mcp/initialize")
    if [ $? -eq 0 ]; then
        echo "✅ MCP initialize passed!"
        echo "Response: $INIT_RESPONSE"
    else
        echo "❌ MCP initialize failed"
    fi
fi
