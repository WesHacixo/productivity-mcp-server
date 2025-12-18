# Ollama Connection Validation

This document describes how to validate the connection to Ollama on Mac Studio and ensure the coder model is available.

**Note:** According to the Anetmacsetup project, Mac Studio should already have the cloud coder model (`qwen3-coder:480b-cloud`) installed. This validation checks that model specifically.

## Quick Validation

### Option 1: Validate Mac Studio via SSH (Recommended)

This validates the Ollama instance on Mac Studio which should already have the cloud coder model:

```bash
cd /Users/damian/Projects/productivity-mcp-server
./scripts/validate_ollama_macstudio.sh
```

This script:
- Establishes SSH connection to Mac Studio
- Checks Ollama status on Mac Studio
- Lists available models (should include `qwen3-coder:480b-cloud`)
- Tests the cloud coder model

### Option 2: Local Validation

If you're running on Mac Studio directly:

```bash
cd /Users/damian/Projects/productivity-mcp-server
go run scripts/validate_ollama.go
```

Or with custom URL/model:

```bash
OLLAMA_URL=http://192.168.12.160:11434 OLLAMA_MODEL=qwen3-coder:480b-cloud go run scripts/validate_ollama.go
```

## Network Configuration

Based on the network setup in the **Anetmacsetup** project, Mac Studio has multiple network interfaces:

- **WiFi (en1):** `192.168.12.160` - Connected to K10 network
- **Thunderbolt Bridge:** `10.10.10.10` or `10.10.20.10` - Direct connection
- **Ethernet (en0):** `10.10.20.11` - eth2Studio network

The validation script automatically tries these IPs:
1. `http://192.168.12.160:11434` (WiFi)
2. `http://10.10.10.10:11434` (Thunderbolt)
3. `http://10.10.20.10:11434` (eth2Studio)
4. `http://localhost:11434` (Local fallback)

## Installing Coder Models

### Recommended Coding Models

1. **DeepSeek Coder** (Recommended)
   ```bash
   ollama pull deepseek-coder
   ```

2. **Qwen3 Coder 30B** (Local)
   ```bash
   ollama pull qwen3-coder:30b
   ```

3. **Qwen3 Coder 480B** (Cloud - requires cloud access)
   ```bash
   ollama run qwen3-coder:480b-cloud
   ```

4. **Stable Code**
   ```bash
   ollama pull stable-code
   ```

5. **CodeLlama**
   ```bash
   ollama pull codellama
   ```

### Remote Installation

If Ollama is running on Mac Studio and you're connecting from another machine:

```bash
ssh macstudio 'ollama pull deepseek-coder'
```

Or if using IP:

```bash
ssh damian@192.168.12.160 'ollama pull deepseek-coder'
```

## Configuring Ollama for Remote Access

By default, Ollama listens on `localhost:11434`. To make it accessible from the network:

### Option 1: Environment Variable

Set `OLLAMA_HOST` environment variable:

```bash
export OLLAMA_HOST=0.0.0.0:11434
ollama serve
```

### Option 2: LaunchAgent (Persistent)

Use the configuration script from the **Anetmacsetup** project:

```bash
cd /Users/damian/Projects/Anetmacsetup
./scripts/mac-studio-thunderbolt/configure-ollama.sh
```

This creates a LaunchAgent that runs Ollama with network access.

## Validation Results

The script performs these checks:

1. **Server Connectivity** - Tests if Ollama API is reachable
2. **Model Listing** - Lists all available models
3. **Model Availability** - Checks if the specified model exists
4. **Model Generation** - Tests a simple generation request

### Example Output

```
🔍 Validating Ollama connection...
   Model: coder

1️⃣ Testing server connectivity...
   Trying http://192.168.12.160:11434...
   ⚠️  http://192.168.12.160:11434: context deadline exceeded
   Trying http://localhost:11434...
   ✅ Server is reachable at http://localhost:11434

2️⃣ Listing available models...
   ✅ Found 4 model(s):
      - mixtral:8x7b-instruct-v0.1-q4_K_S
      - gemma3:12b-it-qat
      - gemma3:4b
      - gemma3:1b

3️⃣ Checking if 'coder' model is available...
   ❌ Model 'coder' not found in available models
   💡 Popular coding models you can install:
      - deepseek-coder (recommended for coding)
      - qwen3-coder:30b (cloud: qwen3-coder:480b-cloud)
      - stable-code
      - codellama

   📥 To install a coder model, run:
      ollama pull deepseek-coder
```

## Troubleshooting

### Connection Timeout

If all IPs timeout:
- Check if Ollama is running: `pgrep -f ollama`
- Check if Ollama is listening: `lsof -i :11434`
- Verify firewall settings
- Ensure you're on the same network

### Model Not Found

If the model isn't available:
- Check available models: `ollama list`
- Pull the model: `ollama pull <model-name>`
- For cloud models, ensure you have cloud access enabled

### Remote Access Issues

If you can't access Ollama remotely:
- Ensure `OLLAMA_HOST` is set to `0.0.0.0:11434` or a specific IP
- Check macOS firewall settings
- Verify network connectivity with `ping <macstudio-ip>`

## Integration with Productivity MCP Server

To use Ollama with the productivity MCP server, set environment variables:

```bash
export OLLAMA_URL=http://192.168.12.160:11434
export OLLAMA_MODEL=deepseek-coder
```

Or add to your `.env` file:

```env
OLLAMA_URL=http://192.168.12.160:11434
OLLAMA_MODEL=deepseek-coder
```

## References

- [Ollama Documentation](https://docs.ollama.com)
- [Ollama Model Library](https://ollama.com/library)
- [Anetmacsetup Network Configuration](/Users/damian/Projects/Anetmacsetup/CURRENT_NETWORK_CONFIG.md)
