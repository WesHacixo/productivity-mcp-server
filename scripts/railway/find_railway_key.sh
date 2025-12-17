#!/bin/bash
# Helper script to find Railway API key in macOS Keychain

echo "🔍 Searching for Railway API key in macOS Keychain..."
echo ""

# List all keychain items and search for railway-related entries
if command -v security >/dev/null 2>&1; then
    echo "Searching keychain for Railway-related entries..."
    echo ""
    
    # Try to find by service name
    security dump-keychain 2>/dev/null | grep -i "railway" | head -10 || echo "No 'railway' found in keychain dump"
    
    echo ""
    echo "Common keychain entry names to check:"
    echo "  - railway-api-key"
    echo "  - railway-token"
    echo "  - Railway API Key"
    echo "  - railway"
    echo ""
    echo "To check a specific keychain entry:"
    echo "  security find-generic-password -s 'entry-name' -w"
    echo ""
    echo "To list all your keychain items (search for 'railway'):"
    echo "  security dump-keychain | grep -i railway"
else
    echo "❌ 'security' command not available (not on macOS?)"
fi
