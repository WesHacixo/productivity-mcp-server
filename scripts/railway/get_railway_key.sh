#!/bin/bash
# Retrieve Railway API key from macOS Keychain
# Usage: ./get_railway_key.sh [service-name]
# Example: ./get_railway_key.sh railway-api-key

ACCOUNT="DAE"
SERVICE="${1:-railway-api-key}"

echo "🔑 Retrieving Railway API key from keychain..."
echo "   Account: $ACCOUNT"
echo "   Service: $SERVICE"
echo ""

# Try to retrieve the key
KEY=$(security find-generic-password -a "$ACCOUNT" -s "$SERVICE" -w 2>&1)

if [ $? -eq 0 ] && [ -n "$KEY" ] && [ ${#KEY} -gt 10 ]; then
    echo "✅ Successfully retrieved key (length: ${#KEY})"
    echo ""
    echo "To use it:"
    echo "   export RAILWAY_API='$KEY'"
    echo ""
    echo "Or use with Railway CLI:"
    echo "   export RAILWAY_TOKEN='$KEY'"
    echo "   railway whoami"
    echo ""
    # Optionally export it
    if [ "$2" == "--export" ]; then
        export RAILWAY_API="$KEY"
        export RAILWAY_TOKEN="$KEY"
        echo "✅ Exported to RAILWAY_API and RAILWAY_TOKEN"
    fi
else
    echo "❌ Failed to retrieve key"
    echo ""
    echo "Error: $KEY"
    echo ""
    echo "Available services for account '$ACCOUNT':"
    security find-generic-password -a "$ACCOUNT" 2>&1 | grep -E "svce" | head -5
    echo ""
    echo "To store a new key:"
    echo "   security add-generic-password -a \"$ACCOUNT\" -s \"$SERVICE\" -w \"\$RAILWAY_API\" -U"
fi
