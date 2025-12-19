# Productivity MCP Server - Claude Desktop Extension

A Claude Desktop extension that provides tools for managing tasks and goals by connecting to the Railway-hosted productivity API.

## Features

- ✅ **Task Management**: Create, list, update, and delete tasks
- ✅ **Goal Tracking**: Create, list, update, and delete goals
- ✅ **AI-Powered Parsing**: Parse natural language into structured tasks
- ✅ **No OAuth Required**: Direct API connection (simpler than remote MCP)
- ✅ **Offline Capable**: Can work with local caching (future enhancement)

## Installation

### Prerequisites

- Claude Desktop installed
- Node.js 18+ (bundled with Claude Desktop)

### Install MCPB CLI

```bash
npm install -g @anthropic-ai/mcpb
```

### Build the Extension

```bash
cd claude-desktop-extension
npm install
mcpb pack
```

This creates a `.mcpb` file that you can install in Claude Desktop.

### Install in Claude Desktop

1. Open Claude Desktop
2. Go to Settings → Extensions
3. Click "Install Extension"
4. Select the `.mcpb` file
5. Configure:
   - **API URL**: `https://productivity-mcp-server-production.up.railway.app` (or your custom URL)
   - **API Key**: (Optional) Your API key for authentication

## Configuration

The extension uses `user_config` from `manifest.json`:

- **api_url**: Your Railway API URL (default: production URL)
- **api_key**: Optional API key for authentication

## Available Tools

### Task Tools

- `list_tasks` - List tasks with optional filters (completed, category, priority)
- `create_task` - Create a new task
- `update_task` - Update an existing task
- `delete_task` - Delete a task
- `parse_task` - Parse natural language into a structured task

### Goal Tools

- `list_goals` - List goals with optional archived filter
- `create_goal` - Create a new goal
- `update_goal` - Update an existing goal
- `delete_goal` - Delete a goal

## Usage Examples

### Create a Task

```
Use the create_task tool to create a task:
- userId: "user-123"
- title: "Finish quarterly report"
- dueDate: "2024-12-20T17:00:00Z"
- priority: 5
- category: "work"
```

### Parse Natural Language

```
Use the parse_task tool:
- input: "Finish report by Friday at 5pm"
- userId: "user-123"
```

### List Tasks

```
Use the list_tasks tool:
- userId: "user-123"
- completed: false
- category: "work"
```

## Development

### Local Testing

You can test the extension locally before bundling:

```bash
# Run the server directly
node index.js
```

### Debugging

The extension logs to stderr, which Claude Desktop captures. Check Claude Desktop logs for debugging.

### Project Structure

```
claude-desktop-extension/
├── manifest.json      # Extension manifest
├── index.js           # MCP server implementation
├── package.json       # Node.js dependencies
└── README.md          # This file
```

## API Integration

The extension connects to the Railway-hosted Go MCP server:

- **Base URL**: Configurable via `api_url` in user config
- **Authentication**: Optional API key via `api_key`
- **Endpoints**: Uses REST API (`/api/tasks`, `/api/goals`, `/api/mcp/parse-task`)

## Troubleshooting

### Extension Not Loading

1. Check that Node.js 18+ is available
2. Verify `manifest.json` is valid JSON
3. Check Claude Desktop logs for errors

### API Connection Issues

1. Verify API URL is correct
2. Check API key if required
3. Test API endpoint directly: `curl https://your-api-url/health`

### Tools Not Appearing

1. Restart Claude Desktop
2. Check that extension is enabled in settings
3. Verify `manifest.json` has correct tool definitions

## Future Enhancements

- [ ] Local caching for offline support
- [ ] Real-time sync via WebSocket
- [ ] System notifications
- [ ] Keyboard shortcuts
- [ ] Quick actions menu

## License

MIT
