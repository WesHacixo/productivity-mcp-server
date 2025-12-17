#!/bin/bash
# Store Railway API key in macOS Keychain
# Follows the pattern: security add-generic-password -a "account" -s "service" -w "$KEY" -U
#
# Usage:
#   export RAILWAY_API='your-token-here'
#   ./store_railway_key.sh
#
# Or specify service name:
#   ./store_railway_key.sh railway-api-key

ACCOUNT="DAE"
SERVICE="${1:-railway-api-key}"

if [ -z "$RAILWAY_API" ]; then
    echo "❌ RAILWAY_API environment variable not set"
    echo ""
    echo "Usage:"
    echo "   export RAILWAY_API='your-token-here'"
    echo "   ./store_railway_key.sh [service-name]"
    echo ""
    echo "Example:"
    echo "   export RAILWAY_API='rw_xxxxxxxxxxxxx'"
    echo "   ./store_railway_key.sh railway-api-key"
    exit 1
fi

echo "🔐 Storing Railway API key in keychain..."
echo "   Account: $ACCOUNT"
echo "   Service: $SERVICE"
echo ""

# Store the key (using -U to update if it exists)
security add-generic-password -a "$ACCOUNT" -s "$SERVICE" -w "$RAILWAY_API" -U

if [ $? -eq 0 ]; then
    echo "✅ Successfully stored key in keychain"
    echo ""
    echo "To retrieve it later:"
    echo "   security find-generic-password -a \"$ACCOUNT\" -s \"$SERVICE\" -w"
    echo ""
    echo "Or use the helper script:"
    echo "   ./get_railway_key.sh $SERVICE"
else
    echo "❌ Failed to store key"
    exit 1
fi
