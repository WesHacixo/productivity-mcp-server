# Repository Structure

## Directory Layout

```
productivity-mcp-server/
├── README.md                 # Main project README
├── TODO.md                   # Current task list
├── .gitignore               # Git ignore rules
├── go.mod                    # Go module definition
├── go.sum                    # Go dependencies
├── Dockerfile               # Docker build config
├── railway.json             # Railway deployment config
│
├── main.go                   # Go server entry point
├── handlers/                 # HTTP handlers
│   ├── auth.go              # OAuth 2.0 authentication
│   ├── claude.go            # Claude AI integration
│   ├── goal.go              # Goal management
│   ├── mcp.go               # MCP protocol handlers
│   └── task.go              # Task management
├── models/                   # Data models
│   └── models.go
├── db/                      # Database clients
│   └── supabase.go
├── middleware/              # HTTP middleware
│   ├── auth.go              # Authentication middleware
│   └── cors.go              # CORS middleware
│
├── docs/                    # Documentation
│   ├── README.md            # Documentation index
│   ├── deployment/          # Deployment guides
│   ├── setup/               # Setup guides
│   ├── integration/         # Integration docs
│   ├── reference/           # Reference docs
│   └── openai-quota.md     # OpenAI quota management
│
├── scripts/                 # Utility scripts
│   ├── railway/             # Railway-related scripts
│   ├── supabase/            # Supabase-related scripts
│   ├── testing/             # Test scripts
│   └── *.py                 # Python utilities
│
└── productivity_tool_app/   # React Native webapp
    ├── app/                  # Expo Router app
    ├── server/               # Node.js backend
    ├── hooks/                # React hooks
    ├── lib/                  # Utilities
    ├── components/           # React components
    ├── supabase/             # Supabase migrations
    └── drizzle/             # Drizzle ORM schema
```

## File Organization

### Root Level
- **README.md** - Project overview, features, quick start
- **TODO.md** - Current tasks and priorities
- **.gitignore** - Git ignore patterns
- **Dockerfile** - Container build config
- **railway.json** - Railway deployment config

### Go Code
- **main.go** - Server entry point, route setup
- **handlers/** - HTTP request handlers
- **models/** - Data structures
- **db/** - Database client implementations
- **middleware/** - HTTP middleware

### Documentation
- **docs/deployment/** - Railway, Docker, deployment guides
- **docs/setup/** - Supabase, MySQL setup guides
- **docs/integration/** - Architecture, integration docs
- **docs/reference/** - MCP, OAuth, security reference

### Scripts
- **scripts/railway/** - Railway API, CLI scripts
- **scripts/supabase/** - Supabase CLI scripts
- **scripts/testing/** - Test and validation scripts
- **scripts/*.py** - Python utilities (quota guard, etc.)

### Webapp
- **productivity_tool_app/** - Complete React Native app
  - See `productivity_tool_app/README.md` for structure

## Key Files

### Configuration
- `.env.example` - Environment variable template
- `go.mod` - Go dependencies
- `Dockerfile` - Container configuration
- `railway.json` - Railway deployment config

### Entry Points
- `main.go` - Go MCP server
- `productivity_tool_app/server/_core/index.ts` - Node.js backend
- `productivity_tool_app/app/_layout.tsx` - React Native app

### Documentation Entry Points
- `README.md` - Start here
- `TODO.md` - What needs to be done
- `docs/README.md` - Documentation index
