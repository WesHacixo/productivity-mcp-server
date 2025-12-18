# Claude Desktop Extension - Alternative Plan

## If MCP OAuth Fails

If the current MCP OAuth implementation continues to have issues, we can pivot to a **Claude Desktop Extension** approach.

## Why Desktop Extension?

### Advantages
- ✅ **No OAuth Complexity** - Direct API access
- ✅ **Native Integration** - Better performance
- ✅ **Easier Debugging** - No redirect URI issues
- ✅ **Simpler Setup** - Just install extension
- ✅ **Better UX** - Seamless integration

### Trade-offs
- ⚠️ **Distribution** - Need to publish to extension store
- ⚠️ **Platform-Specific** - Different code for Mac/Windows
- ⚠️ **Maintenance** - Extension updates required

## Architecture

```
┌─────────────────┐
│ Claude Desktop  │
│   Extension     │
│  (Native Code) │
└────────┬────────┘
         │
         │ Direct API Calls
         │ (No OAuth)
         │
         ▼
┌─────────────────┐
│  MCP Server     │
│  (Railway)      │
│                 │
│  - Tasks API    │
│  - Goals API    │
│  - Tools API    │
└─────────────────┘
```

## Implementation Options

### Option 1: Native Extension (Recommended)

**Technology:**
- **macOS:** Swift/SwiftUI
- **Windows:** C#/.NET or Electron

**Features:**
- Native UI integration
- Direct API calls
- Local storage/caching
- System notifications

### Option 2: Electron Extension

**Technology:**
- Electron + TypeScript/React

**Features:**
- Cross-platform (one codebase)
- Web technologies
- Easier development
- Larger bundle size

### Option 3: Browser Extension

**Technology:**
- Chrome Extension API
- Manifest V3

**Features:**
- Works with Claude web
- Cross-platform
- Easy distribution
- Limited native access

## Development Plan

### Phase 1: Proof of Concept (1-2 weeks)
1. Create basic extension structure
2. Implement API client
3. Test with Railway server
4. Basic UI for tasks/goals

### Phase 2: Core Features (2-3 weeks)
1. Task management UI
2. Goal tracking UI
3. Real-time sync
4. Local caching

### Phase 3: Advanced Features (2-3 weeks)
1. Notifications
2. Quick actions
3. Keyboard shortcuts
4. System integration

### Phase 4: Distribution (1 week)
1. Code signing
2. Extension store submission
3. Documentation
4. User guide

## API Requirements

The MCP server would need:
- ✅ REST API (already exists)
- ✅ Authentication (API key or token)
- ✅ CORS enabled
- ✅ WebSocket for real-time (optional)

## Current Status

**MCP OAuth:** In progress (this iteration)  
**Extension:** Backup plan if OAuth fails

## Decision Point

**If this OAuth iteration fails:**
1. Document what didn't work
2. Switch to extension development
3. Use direct API authentication
4. Focus on native integration

## Resources

- Claude Desktop Extension Docs: (to be researched)
- Electron Extension Guide: https://www.electronjs.org/docs
- Chrome Extension Guide: https://developer.chrome.com/docs/extensions
