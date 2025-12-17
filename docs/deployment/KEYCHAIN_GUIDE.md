# macOS Keychain Guide for Railway API Key

This guide shows how to securely store and retrieve your Railway API key using macOS Keychain, following the pattern from the OpenAI example.

## Pattern

**Store:**
```bash
security add-generic-password -a "account-name" -s "service-name" -w "$KEY" -U
```

**Retrieve:**
```bash
security find-generic-password -a "account-name" -s "service-name" -w
```

The `-w` flag prints only the secret value (for storing) or outputs it (for retrieving).

## Quick Start

### 1. Store Your Railway API Key

```bash
# Set your API key (get it from https://railway.com/account/tokens)
export RAILWAY_API='your-token-here'

# Store it in keychain
./scripts/store_railway_key.sh railway-api-key
```

Or manually:
```bash
security add-generic-password -a "DAE" -s "railway-api-key" -w "$RAILWAY_API" -U
```

### 2. Retrieve Your Railway API Key

**Using the helper script:**
```bash
./scripts/get_railway_key.sh railway-api-key
```

**Or manually:**
```bash
export RAILWAY_API=$(security find-generic-password -a "DAE" -s "railway-api-key" -w)
```

### 3. Use with Scripts

The Python script will automatically try to retrieve from keychain:
```bash
python3 scripts/get_railway_url.py
```

Or export it first:
```bash
export RAILWAY_API=$(security find-generic-password -a "DAE" -s "railway-api-key" -w)
python3 scripts/get_railway_url.py
```

## Keychain Entry Details

- **Account**: `DAE` (your account label)
- **Service**: `railway-api-key` (recommended service name)
- **-U flag**: Updates the entry if it already exists

## Viewing Keychain Metadata

To see the credential metadata (without the value):
```bash
security find-generic-password -a "DAE" -s "railway-api-key"
```

## Updating/Rotating Keys

Use the `-U` flag to update in place:
```bash
export RAILWAY_API='new-token-here'
security add-generic-password -a "DAE" -s "railway-api-key" -w "$RAILWAY_API" -U
```

Or use the helper script:
```bash
export RAILWAY_API='new-token-here'
./scripts/store_railway_key.sh railway-api-key
```

## Troubleshooting

**If keychain access requires user interaction:**
- The keychain might be locked
- You may need to unlock it in System Settings > Passwords
- Or approve the access when prompted

**If service name not found:**
- Check what services exist: `security find-generic-password -a "DAE"`
- Use the correct service name when retrieving
- Or re-store with a known service name

## Integration with Railway CLI

The Railway CLI uses its own authentication. To use the API key programmatically:

```bash
# Retrieve from keychain
export RAILWAY_TOKEN=$(security find-generic-password -a "DAE" -s "railway-api-key" -w)

# Use with Railway GraphQL API
curl -H "Authorization: Bearer $RAILWAY_TOKEN" \
  https://backboard.railway.app/graphql/v2 \
  -d '{"query": "..."}'
```
