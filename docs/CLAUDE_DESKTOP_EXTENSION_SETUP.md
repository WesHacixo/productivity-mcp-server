# Claude Desktop Extension - Setup Guide

## Overview

We've pivoted from OAuth-based remote MCP to a **Claude Desktop Extension** using MCP Bundles (MCPB). This approach:

- ✅ **No OAuth complexity** - Direct API connection
- ✅ **Simpler setup** - Just install the `.mcpb` file
- ✅ **Better UX** - Native integration with Claude Desktop
- ✅ **Offline capable** - Can work with local caching

## Architecture

```
Claude Desktop
    ↓
MCP Extension (Node.js, stdio)
    ↓
Railway API (Go MCP Server)
    ↓
Supabase Database
```

## Quick Start

### 1. Install MCPB CLI

```bash
npm install -g @anthropic-ai/mcpb
```

### 2. Build the Extension

```bash
cd claude-desktop-extension
npm install
npm run build
```

This creates `productivity-mcp-server.mcpb` in the current directory.

### 3. Install in Claude Desktop

1. Open Claude Desktop
2. Go to **Settings** → **Extensions** (or **Connectors**)
3. Click **"Install Extension"** or **"Add Extension"**
4. Select the `productivity-mcp-server.mcpb` file
5. Configure:
   - **API URL**: `https://productivity-mcp-server-production.up.railway.app`
   - **API Key**: (Optional) Leave empty for now, or add if you implement API key auth

### 4. Verify Installation

1. Restart Claude Desktop
2. In a Claude conversation, the extension should be available
3. Try: "List my tasks" or "Create a task called 'Test'"

## Configuration

The extension uses `user_config` from `manifest.json`:

### API URL

- **Default**: `https://productivity-mcp-server-production.up.railway.app`
- **Custom**: Set your own Railway URL or local development URL
- **Local Dev**: `http://localhost:8080` (if running Go server locally)

### API Key (Optional)

- Currently optional (can be empty)
- Future: Can implement API key authentication in Go server
- If implemented, add your API key here

## Available Tools

### Task Management

- **`list_tasks`** - List tasks with filters (completed, category, priority)
- **`create_task`** - Create a new task
- **`update_task`** - Update an existing task
- **`delete_task`** - Delete a task
- **`parse_task`** - Parse natural language into structured task

### Goal Management

- **`list_goals`** - List goals with optional archived filter
- **`create_goal`** - Create a new goal
- **`update_goal`** - Update an existing goal
- **`delete_goal`** - Delete a goal

## Usage Examples

### Create a Task

```
Claude, use the create_task tool to create a task:
- userId: "user-123"
- title: "Finish quarterly report"
- dueDate: "2024-12-20T17:00:00Z"
- priority: 5
- category: "work"
```

### Parse Natural Language

```
Claude, use the parse_task tool:
- input: "Finish report by Friday at 5pm"
- userId: "user-123"
```

### List Tasks

```
Claude, use the list_tasks tool:
- userId: "user-123"
- completed: false
- category: "work"
```

## Development

### Project Structure

```
claude-desktop-extension/
├── manifest.json      # Extension manifest (user config)
├── index.js           # MCP server implementation
├── package.json       # Node.js dependencies
├── README.md          # Extension documentation
└── .gitignore         # Git ignore rules
```

### Local Testing

Test the extension before bundling:

```bash
# Run the server directly (stdio mode)
node index.js
```

### Building

```bash
npm run build
# Creates: productivity-mcp-server.mcpb
```

### Debugging

- Extension logs to `stderr` (captured by Claude Desktop)
- Check Claude Desktop logs for errors
- Test API endpoints directly: `curl https://your-api-url/health`

## Troubleshooting

### Extension Not Loading

1. **Check Node.js version**: Must be 18+ (bundled with Claude Desktop)
2. **Verify manifest.json**: Must be valid JSON
3. **Check Claude Desktop logs**: Look for MCP errors

### API Connection Issues

1. **Verify API URL**: Test with `curl https://your-api-url/health`
2. **Check API key**: If required, verify it's correct
3. **Network issues**: Ensure Claude Desktop can reach Railway

### Tools Not Appearing

1. **Restart Claude Desktop**: Extensions load on startup
2. **Check extension enabled**: Settings → Extensions
3. **Verify manifest.json**: Tool definitions must be correct

### Build Errors

1. **MCPB CLI installed?**: `npm install -g @anthropic-ai/mcpb`
2. **Dependencies installed?**: `npm install`
3. **Check package.json**: Must have `"type": "module"`

## API Integration

The extension connects to the Railway-hosted Go MCP server:

### Endpoints Used

- `GET /api/tasks/user/:userId` - List tasks
- `POST /api/tasks` - Create task
- `PUT /api/tasks/:id` - Update task
- `DELETE /api/tasks/:id` - Delete task
- `GET /api/goals/user/:userId` - List goals
- `POST /api/goals` - Create goal
- `PUT /api/goals/:id` - Update goal
- `DELETE /api/goals/:id` - Delete goal
- `POST /api/mcp/parse-task` - Parse natural language

### Authentication

Currently optional (can add API key auth later):

```javascript
if (API_KEY) {
  headers["Authorization"] = `Bearer ${API_KEY}`;
}
```

## Next Steps

1. ✅ Extension created and ready to build
2. ⏳ Test in Claude Desktop
3. ⏳ Add API key authentication (optional)
4. ⏳ Add local caching for offline support
5. ⏳ Add real-time sync via WebSocket (optional)

## Comparison: Remote MCP vs Desktop Extension

| Feature | Remote MCP (OAuth) | Desktop Extension (MCPB) |
|---------|-------------------|---------------------------|
| Setup Complexity | High (OAuth flow) | Low (install .mcpb) |
| Authentication | OAuth 2.1 + PKCE | Optional API key |
| Distribution | URL + OAuth config | .mcpb file |
| Offline Support | No | Yes (with caching) |
| Debugging | Complex (redirects) | Simple (stdio logs) |
| Performance | Network latency | Local execution |

## Resources

- [MCPB Documentation](https://support.claude.com/en/articles/12922929-building-desktop-extensions-with-mcpb)
- [MCP SDK](https://github.com/modelcontextprotocol/sdk)
- [Claude Desktop Extensions](https://support.claude.com/en/articles/11175166-about-custom-integrations-using-remote-mcp)
