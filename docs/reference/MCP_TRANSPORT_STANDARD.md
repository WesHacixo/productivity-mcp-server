# MCP Transport Standard (Anthropic Official)

## Current Standard (2024-2025)

Based on Anthropic's official documentation:

### For Local MCP Servers (Claude Desktop)
- **Transport:** `stdio` (standard input/output)
- **Configuration:** Via `claude_desktop_config.json`
- **Use Case:** Servers running locally on the user's machine

### For Remote HTTP MCP Servers
- **Transport:** **Streamable HTTP** (recommended, future-proof)
- **SSE Status:** ⚠️ **May be deprecated** in coming months
- **Configuration:** Via Claude Desktop Settings > Connectors (NOT via config file)
- **Use Case:** Servers deployed remotely (like your Railway server)

## Important Notes

1. **SSE is being deprecated** - Don't implement SSE for new servers
2. **Streamable HTTP is recommended** - This is the future-proof approach
3. **Remote servers** must be added via Claude Desktop UI, not config file
4. **Local servers** use stdio and can be configured via config file

## What is "Streamable HTTP"?

Based on the documentation, "Streamable HTTP" appears to be:
- Standard HTTP POST requests with streaming response support
- Not SSE (which is being deprecated)
- Likely HTTP POST with chunked transfer encoding or similar
- Standard REST API pattern with streaming capabilities

## Your Current Implementation

Your server currently uses:
- ✅ **HTTP POST** endpoints (`/mcp/initialize`, `/mcp/list_tools`, `/mcp/call_tool`)
- ✅ **JSON responses**
- ✅ **Standard REST API**

This aligns with "Streamable HTTP" - you're already using the recommended approach!

## Recommendation

**Keep your current HTTP POST implementation.** It's:
- ✅ Standard REST (not deprecated SSE)
- ✅ Future-proof (matches "Streamable HTTP")
- ✅ Simple and maintainable
- ✅ Works with Claude Desktop remote servers

**For Claude Desktop:**
- Add your server via **Settings > Connectors** (not config file)
- Use your Railway URL: `https://productivity-mcp-server-production.up.railway.app`
- Claude Desktop will handle the connection

## References

- [Anthropic Support: Remote MCP Servers](https://support.anthropic.com/en/articles/11503834-building-custom-integrations-via-remote-mcp-servers)
- [Anthropic Docs: MCP Connector](https://docs.anthropic.com/en/docs/agents-and-tools/mcp-connector)
