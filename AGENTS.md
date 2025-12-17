# Repository Guidelines

## Project Structure & Module Organization
- `main.go` wires Gin routes and loads handlers, middleware, and Supabase clients defined under `handlers/`, `middleware/`, and `db/` respectively.
- Use `models/models.go` for shared data shapes and `db/supabase.go` for the Supabase client.
- `handlers/` splits REST logic into task, goal, Claude AI, and MCP protocol handlers; keep new endpoints in the appropriate file.
- Keep helper libraries under `middleware/` when they apply broadly (e.g., CORS).

## Build, Test, and Development Commands
- `go run main.go` – boots the server on `localhost:8000` using the local `.env` settings.
- `go build -o server .` – produces the `server` binary for manual execution or container builds.
- `docker build -t productivity-mcp-server .` – packages the app for deployment (matching Dockerfile instructions).
- `go test ./...` – runs every Go test; run before committing.

## Coding Style & Naming Conventions
- Follow the Go idioms enforced by `gofmt`; run it on any edited file before committing.
- Keep handler functions short and name them to reflect HTTP verbs (`CreateTask`, `ListGoals`).
- Exported structs and fields use PascalCase while locals stay camelCase.
- Prefer descriptive names for routes and environment variables (see `.env.example`).

## Testing Guidelines
- Use Go’s built-in testing framework; place tests in `_test.go` files adjacent to the code they verify.
- Focus on pure logic and handler behavior without relying on a live Supabase instance (mock external calls where possible).
- Always run `go test ./...` locally and note any skipped or failing packages in PRs.

## Commit & Pull Request Guidelines
- Commit messages should describe what changed in an imperative tone (e.g., “Add goal handler”).
- PRs require a short description, automated test status, and linked issue or ticket when available.
- Attach screenshots or request modal logs only when UI or MCP interactions are impacted.

## Security & Configuration Tips
- Copy `.env.example` to `.env` and fill in `SUPABASE_*`, `CLAUDE_API_KEY`, and optional `PORT` before running locally.
- Keep Supabase credentials and Claude keys out of the repo; rely on environment variables in containers and CI.
