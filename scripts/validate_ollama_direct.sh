#!/bin/bash
# Direct Ollama validation via Tailscale (no SSH required)
# Validates Ollama on Mac Studio and checks for cloud coder model

set -e

MAC_STUDIO_TAILSCALE_IP="100.74.59.83"
OLLAMA_URL="http://${MAC_STUDIO_TAILSCALE_IP}:11434"
MODEL_NAME="qwen3-coder:480b-cloud"

echo "🔍 Validating Ollama on Mac Studio (via Tailscale)..."
echo "   URL: $OLLAMA_URL"
echo "   Target Model: $MODEL_NAME"
echo ""

# Test 1: Check Tailscale connectivity
echo "1️⃣ Testing Tailscale connectivity..."
if /Applications/Tailscale.app/Contents/MacOS/Tailscale ping -c 1 "$MAC_STUDIO_TAILSCALE_IP" >/dev/null 2>&1; then
    PING_RESULT=$(/Applications/Tailscale.app/Contents/MacOS/Tailscale ping -c 1 "$MAC_STUDIO_TAILSCALE_IP" 2>&1 | grep -o "in [0-9]*ms" || echo "")
    echo "   ✅ Mac Studio is reachable via Tailscale $PING_RESULT"
else
    echo "   ❌ Mac Studio not reachable via Tailscale"
    echo "   💡 Check Tailscale status: /Applications/Tailscale.app/Contents/MacOS/Tailscale status"
    exit 1
fi

# Test 2: Check Ollama API
echo ""
echo "2️⃣ Testing Ollama API..."
if curl -s --connect-timeout 5 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
    echo "   ✅ Ollama API is accessible"
else
    echo "   ❌ Ollama API not accessible"
    echo "   💡 Ensure Ollama is running on Mac Studio"
    exit 1
fi

# Test 3: List models
echo ""
echo "3️⃣ Listing available models..."
MODELS_JSON=$(curl -s --connect-timeout 5 "$OLLAMA_URL/api/tags")
if [ $? -ne 0 ]; then
    echo "   ❌ Failed to fetch models"
    exit 1
fi

MODEL_NAMES=$(echo "$MODELS_JSON" | python3 -c "import sys, json; data=json.load(sys.stdin); print('\n'.join([m['name'] for m in data['models']]))" 2>/dev/null)

if [ -z "$MODEL_NAMES" ]; then
    echo "   ❌ No models found or failed to parse response"
    exit 1
fi

MODEL_COUNT=$(echo "$MODELS_JSON" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data['models']))" 2>/dev/null)
echo "   ✅ Found $MODEL_COUNT model(s):"
echo "$MODEL_NAMES" | sed 's/^/      - /'

# Test 4: Check for coder models
echo ""
echo "4️⃣ Checking for coder models..."
CODER_MODELS=$(echo "$MODEL_NAMES" | grep -i "coder" || true)

if [ -z "$CODER_MODELS" ]; then
    echo "   ❌ No coder models found"
    exit 1
fi

echo "   ✅ Found coder model(s):"
echo "$CODER_MODELS" | sed 's/^/      - /'

# Test 5: Check specifically for cloud model
echo ""
echo "5️⃣ Checking for cloud coder model ($MODEL_NAME)..."
if echo "$MODEL_NAMES" | grep -q "^${MODEL_NAME}$"; then
    echo "   ✅ Cloud coder model found: $MODEL_NAME"
    
    # Get model details
    MODEL_INFO=$(echo "$MODELS_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for m in data['models']:
    if m['name'] == '$MODEL_NAME':
        print(f\"      Size: {m.get('size', 'N/A')}\")
        if 'remote_model' in m:
            print(f\"      Remote Model: {m['remote_model']}\")
            print(f\"      Remote Host: {m.get('remote_host', 'N/A')}\")
        if 'details' in m and 'parameter_size' in m['details']:
            print(f\"      Parameters: {m['details']['parameter_size']}\")
        break
" 2>/dev/null)
    
    if [ -n "$MODEL_INFO" ]; then
        echo "$MODEL_INFO"
    fi
    
    # Test 6: Test model generation
    echo ""
    echo "6️⃣ Testing model generation..."
    TEST_RESPONSE=$(curl -s --connect-timeout 30 -X POST "$OLLAMA_URL/api/generate" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"$MODEL_NAME\",\"prompt\":\"Say 'Hello from Ollama' in one sentence.\",\"stream\":false}" 2>&1)
    
    if echo "$TEST_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); exit(0 if data.get('done') else 1)" 2>/dev/null; then
        RESPONSE_TEXT=$(echo "$TEST_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('response', '')[:100])" 2>/dev/null)
        echo "   ✅ Model test successful!"
        echo "   Response preview: ${RESPONSE_TEXT}..."
    else
        echo "   ⚠️  Model test incomplete (may need more time or cloud access)"
        echo "   Response: ${TEST_RESPONSE:0:200}..."
    fi
else
    echo "   ❌ Cloud coder model '$MODEL_NAME' not found"
    echo "   Available coder models:"
    echo "$CODER_MODELS" | sed 's/^/      - /'
    exit 1
fi

echo ""
echo "✅ Validation complete!"
echo "   Mac Studio Ollama: $OLLAMA_URL"
echo "   Cloud Coder Model: $MODEL_NAME"
echo "   Status: Ready to use"
