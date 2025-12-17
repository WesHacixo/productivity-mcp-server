# Repository Guidelines

## Purpose & Non-Negotiables
This Go-based MCP server powers a productivity webapp that ingests documents, extracts scheduling data, and surfaces task lists and objectives; the service must stay safe-by-default, observable, and predictable while remaining correct and low maintenance.
- No secrets in repo, docs, or logs; propagate sensitive settings through `.env.example` and runtime environment variables.
- Every externally-visible behavior change ships with tests (or a documented exception) plus updated docs.
- Favor small, reviewable diffs—do not try to “boil the ocean.”

## Project Structure & Module Organization
- `main.go` wires Gin routes, MCP endpoints, middleware, and the Supabase client; keep the entrypoint lean.
- `handlers/` holds task, goal, Claude AI, and MCP REST handlers; place new endpoints beside their feature’s handler file.
- Shared data lives in `models/models.go`, Supabase helpers in `db/supabase.go`, middleware utilities in `middleware/`, and any additional helpers near the feature that uses them.
- This repo does not yet use `cmd/`, `internal/`, or `pkg/`; keep modules simple until complexity demands new packages.
- Configuration templates live in `.env.example`; refer to it when documenting new env vars.

## Build, Test, Run
- `gofmt -w .` (or `go fmt ./...`) — enforce formatting before committing.
- `go vet ./...` — catch common Go mistakes early.
- `go test ./...` — run unit/regression suites locally and mention results in PRs.
- `go test -race ./...` — optional concurrency sanity check for sensitive changes.
- `go run main.go` (or `go build -o server . && ./server`) — run locally against your `.env` for manual verification.
- `docker build -t productivity-mcp-server .` — create the container image referenced in `Dockerfile` for deployment.

## Coding Style & Design
- Keep transport handlers thin: route → validate → call service → map response.
- Favor explicit types/errors over reflection; thread `context.Context` through services with timeouts for network calls.
- Structure logs (request/trace IDs when available) over prose and never log secrets.
- Stick to Go naming: PascalCase for exported symbols, camelCase for locals, and verb-prefixed handler names (`CreateTask`, `ListGoals`).

## Testing Guidelines
- Use table-driven tests in `_test.go` files beside the code they cover.
- Cover config parsing, error paths, and integration boundaries (mock Supabase/Claude calls rather than hitting live services).
- When modifying behavior, add a regression test first; if you must skip suites, note it explicitly in the PR.

## Model Policy Invariant (Codex + API)
- Behavioral: default to `gpt-5.1-codex-mini` for small edits/tests/docs/refactors (~150 LOC); escalate to `gpt-5.1-codex-max` for multi-file, concurrency-sensitive, or security work.
- Enforced: model name must come from `OPENAI_MODEL` (or equivalent config) defaulting to `gpt-5.1-codex-mini`, validated against an allowlist (`gpt-5.1-codex-mini`, `gpt-5.1-codex-max`), and covered by a unit test that fails fast on invalid strings.

## Commit & Pull Request Guidelines
- Keep commits imperative and explain the “why,” not just the “what” (e.g., “Add mocked Supabase client”).
- PRs include summary, test evidence (or justified skips), risk notes, and config/docs updates for behavior changes.
- Touching auth/keys/network boundaries also requires a short threat/risk note.

## Security & Configuration Tips
- Copy `.env.example` to `.env` and populate `SUPABASE_*`, `CLAUDE_API_KEY`, `PORT`, and other required env vars before running locally.
- Keep Supabase and Claude credentials out of version control; rely on environment variables for CI/deploy.

## Agent Workflow (How Codex Should Operate Here)
1. Read the tree and existing patterns before coding.
2. Share a brief plan (a few bullet points) prior to implementation.
3. Run relevant tests or explain why they could not be run.
4. Provide a concise changelog and cite any follow-up steps.
