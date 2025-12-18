#!/bin/bash
# Validate Ollama connection on Mac Studio via SSH
# Checks for the cloud coder model (qwen3-coder:480b-cloud)

set -e

echo "🔍 Validating Ollama on Mac Studio..."
echo ""

# Try different SSH connection methods (Tailscale first since it was working yesterday)
MAC_STUDIO_HOSTS=(
    "damiantapia@100.74.59.83"  # Tailscale IP (mac-studio)
    "eth2studio"                # eth2Studio network
    "damiantapia@10.10.10.10"   # Thunderbolt
    "damiantapia@10.10.20.10"   # eth2Studio IP
    "damiantapia@192.168.12.160" # WiFi
)

SSH_SUCCESS=false
SSH_HOST=""

# Try to find working SSH connection
for host in "${MAC_STUDIO_HOSTS[@]}"; do
    echo "Trying SSH connection: $host..."
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$host" "echo 'SSH OK'" >/dev/null 2>&1; then
        SSH_SUCCESS=true
        SSH_HOST="$host"
        echo "✅ SSH connection successful: $host"
        echo ""
        break
    else
        echo "⚠️  Connection failed: $host"
    fi
done

if [ "$SSH_SUCCESS" = false ]; then
    echo "❌ Could not establish SSH connection to Mac Studio"
    echo ""
    echo "💡 Troubleshooting:"
    echo "   1. Ensure Mac Studio is powered on"
    echo "   2. Check network connectivity: ping 10.10.10.10 or ping 10.10.20.10"
    echo "   3. Verify SSH is enabled on Mac Studio"
    echo "   4. Check SSH key configuration in ~/.ssh/config"
    exit 1
fi

# Check Ollama on Mac Studio
echo "1️⃣ Checking Ollama status on Mac Studio..."
if ssh "$SSH_HOST" "pgrep -f ollama > /dev/null" 2>/dev/null; then
    echo "   ✅ Ollama is running on Mac Studio"
else
    echo "   ⚠️  Ollama process not found (may still be accessible via API)"
fi

# Check Ollama API accessibility
echo ""
echo "2️⃣ Testing Ollama API on Mac Studio..."
OLLAMA_URLS=(
    "http://100.74.59.83:11434"  # Tailscale IP (mac-studio)
    "http://localhost:11434"      # Via SSH localhost
    "http://10.10.10.10:11434"    # Thunderbolt
    "http://10.10.20.10:11434"    # eth2Studio
    "http://192.168.12.160:11434" # WiFi
)

API_SUCCESS=false
OLLAMA_URL=""

# Try localhost via SSH first
if ssh "$SSH_HOST" "curl -s --connect-timeout 3 http://localhost:11434/api/tags > /dev/null" 2>/dev/null; then
    API_SUCCESS=true
    OLLAMA_URL="http://localhost:11434"
    echo "   ✅ Ollama API accessible on Mac Studio (localhost)"
else
    # Try remote URLs
    for url in "${OLLAMA_URLS[@]}"; do
        if curl -s --connect-timeout 3 "$url/api/tags" > /dev/null 2>&1; then
            API_SUCCESS=true
            OLLAMA_URL="$url"
            echo "   ✅ Ollama API accessible at $url"
            break
        fi
    done
fi

if [ "$API_SUCCESS" = false ]; then
    echo "   ❌ Ollama API not accessible"
    echo "   💡 Ensure Ollama is running and configured for network access"
    exit 1
fi

# List models on Mac Studio
echo ""
echo "3️⃣ Listing models on Mac Studio..."
if [ "$OLLAMA_URL" = "http://localhost:11434" ]; then
    # Use SSH to access localhost
    MODELS=$(ssh "$SSH_HOST" "curl -s http://localhost:11434/api/tags" | grep -o '"name":"[^"]*"' | sed 's/"name":"//;s/"//')
else
    # Direct API access
    MODELS=$(curl -s "$OLLAMA_URL/api/tags" | grep -o '"name":"[^"]*"' | sed 's/"name":"//;s/"//')
fi

echo "   Available models:"
echo "$MODELS" | sed 's/^/      - /'

# Check for coder models
echo ""
echo "4️⃣ Checking for coder models..."
CODER_MODELS=$(echo "$MODELS" | grep -i "coder" || true)

if [ -z "$CODER_MODELS" ]; then
    echo "   ❌ No coder models found"
    echo "   💡 Expected: qwen3-coder:480b-cloud or similar"
    exit 1
else
    echo "   ✅ Found coder model(s):"
    echo "$CODER_MODELS" | sed 's/^/      - /'
    
    # Check specifically for the cloud model
    if echo "$MODELS" | grep -q "qwen3-coder.*cloud"; then
        CLOUD_MODEL=$(echo "$MODELS" | grep "qwen3-coder.*cloud" | head -1)
        echo ""
        echo "   ✅ Cloud coder model found: $CLOUD_MODEL"
        
        # Test the model
        echo ""
        echo "5️⃣ Testing cloud coder model..."
        if [ "$OLLAMA_URL" = "http://localhost:11434" ]; then
            RESPONSE=$(ssh "$SSH_HOST" "curl -s http://localhost:11434/api/generate -d '{\"model\":\"$CLOUD_MODEL\",\"prompt\":\"Say hello\",\"stream\":false}'" 2>/dev/null | grep -o '"response":"[^"]*"' | sed 's/"response":"//;s/"//' | head -c 100)
        else
            RESPONSE=$(curl -s "$OLLAMA_URL/api/generate" -d "{\"model\":\"$CLOUD_MODEL\",\"prompt\":\"Say hello\",\"stream\":false}" 2>/dev/null | grep -o '"response":"[^"]*"' | sed 's/"response":"//;s/"//' | head -c 100)
        fi
        
        if [ -n "$RESPONSE" ]; then
            echo "   ✅ Model test successful"
            echo "   Response preview: ${RESPONSE}..."
        else
            echo "   ⚠️  Model test incomplete (may need more time)"
        fi
    fi
fi

echo ""
echo "✅ Validation complete!"
echo "   Mac Studio Ollama is accessible and has coder models available"
echo "   Connection: $SSH_HOST"
echo "   Ollama URL: $OLLAMA_URL"
