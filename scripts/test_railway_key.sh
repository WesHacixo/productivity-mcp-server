#!/bin/bash
# Quick test to retrieve Railway API key from keychain

echo "Testing keychain access for Railway API key..."
echo ""

# Try to get the key
KEY=$(security find-generic-password -a "DAE" -w 2>&1)

if [ $? -eq 0 ] && [ -n "$KEY" ] && [ ${#KEY} -gt 10 ]; then
    echo "✅ Successfully retrieved key from keychain!"
    echo "Key length: ${#KEY} characters"
    echo "First 10 chars: ${KEY:0:10}..."
    echo ""
    echo "You can now run:"
    echo "  export RAILWAY_API='$KEY'"
    echo "  python3 scripts/get_railway_url.py"
else
    echo "❌ Could not retrieve key from keychain"
    echo "Error: $KEY"
    echo ""
    echo "This might require:"
    echo "  1. User interaction (password prompt)"
    echo "  2. The keychain entry might be empty"
    echo "  3. Permission issues"
    echo ""
    echo "Alternative: Set it as environment variable:"
    echo "  export RAILWAY_API='your-token'"
    echo "  python3 scripts/get_railway_url.py"
fi
