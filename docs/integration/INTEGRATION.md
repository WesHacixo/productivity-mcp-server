# Webapp and MCP Server Integration

This document describes how the React Native/Expo webapp integrates with the Go MCP server.

## Architecture

```
React Native App (Expo)
    ↓
Node.js/Express Server (tRPC)
    ↓
Go MCP Server (REST API)
    ↓
Supabase Database
```

## Setup

### 1. Environment Variables

The webapp server needs the MCP server URL:

**Local Development:**
```bash
# In productivity_tool_app/.env or server environment
MCP_SERVER_URL=http://localhost:8080
```

**Production (Railway):**
```bash
# Get your Railway URL from: Railway Dashboard → Your Service → Settings → Domains
MCP_SERVER_URL=https://your-app-name.up.railway.app
```

**If both services are in the same Railway project:**
```bash
# Use Railway's internal service discovery
MCP_SERVER_URL=http://your-mcp-service.railway.internal:8080
# Or use the public URL
MCP_SERVER_URL=https://your-mcp-service.up.railway.app
```

### 2. Running the Services

**Terminal 1: Go MCP Server**
```bash
cd /path/to/productivity-mcp-server
go run main.go
# Server runs on port 8080
```

**Terminal 2: Node.js API Server**
```bash
cd productivity_tool_app
pnpm install
pnpm dev:server
# Server runs on port 3000
```

**Terminal 3: Expo Metro Bundler**
```bash
cd productivity_tool_app
pnpm dev:metro
# Metro runs on port 8081
```

### 3. Feature Flag

The webapp can use either:
- **API mode**: Connects to Go MCP server via tRPC (default)
- **Local storage mode**: Uses AsyncStorage (offline)

Set in environment:
```bash
EXPO_PUBLIC_USE_API=true  # Use API (default)
EXPO_PUBLIC_USE_API=false # Use local storage
```

## API Integration

### tRPC Routers

The webapp includes tRPC routers that proxy requests to the Go MCP server:

- `server/routers/task.ts` - Task operations
- `server/routers/goal.ts` - Goal operations

### Hooks

New API hooks are available:

- `hooks/use-tasks-api.ts` - Task management via API
- `hooks/use-goals-api.ts` - Goal management via API

The UI components automatically use the API hooks when `EXPO_PUBLIC_USE_API=true`.

## Data Flow

1. **User Action**: User creates/updates a task in the React Native app
2. **Hook Call**: `useTasksAPI()` hook is called
3. **tRPC Call**: Hook makes tRPC call to Node.js server
4. **Proxy Request**: Node.js server makes HTTP request to Go MCP server
5. **Database Update**: Go MCP server updates Supabase
6. **Response**: Response flows back through the chain
7. **UI Update**: React Query invalidates cache and refetches

## Troubleshooting

### MCP Server Not Responding

1. Check if Go server is running: `curl http://localhost:8080/health`
2. Verify `MCP_SERVER_URL` environment variable
3. Check CORS settings in Go server (should allow requests from Node.js server)

### Data Not Syncing

1. Verify Supabase credentials in Go server `.env`
2. Check Go server logs for errors
3. Verify user_id is being passed correctly

### Type Mismatches

The Go server returns Supabase format (snake_case), which is transformed to app format (camelCase) in the tRPC routers.

## Development

To develop locally:

1. Start Go MCP server on port 8080
2. Start Node.js server on port 3000
3. Start Expo Metro on port 8081
4. Set `EXPO_PUBLIC_USE_API=true` in webapp environment

## Production Deployment

1. Deploy Go MCP server (Railway, Render, Fly.io)
2. Set `MCP_SERVER_URL` in Node.js server environment
3. Deploy Node.js server
4. Deploy Expo webapp
