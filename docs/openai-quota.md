# OpenAI Free-tier Guard

This repository ships a small helper that keeps your OpenAI key sleeping until the paid plan has been exhausted and ensures every free-tier request stays within the documented model/token limits.

## Commands

1. `scripts/openai_quota_guard.py status [--allowlist]`
   - Shows the daily remaining tokens for each bucket and how many tokens are left on the paid plan.
   - Use `--allowlist` to list the approved models for each bucket.

2. `scripts/openai_quota_guard.py set-plan <tokens>`
   - Update how many tokens remain on your paid plan. As long as this number is greater than zero, the helper refuses to expose `OPENAI_API_KEY` so all traffic stays on the plan.

3. `scripts/openai_quota_guard.py request --model <model> --tokens <estimated>`
   - Validate a planned OpenAI request before touching the key. It checks the allowlist, ensures you have daily tokens remaining, and only then prints the secure `security find-generic-password ...` command to expose the key.
   - Token buckets reset automatically every UTC day; use `reset` if you need to reset manually.

## Workflow

1. Keep `claude` or other paid-plan traffic running normally while `set-plan` reports tokens left (`set-plan` can be updated from whatever billing/usage API you already use).
2. Once the paid plan is drained (`set-plan 0`), run `request` before any OpenAI call. If it succeeds, run the `security find-generic-password ...` command it prints and keep that `OPENAI_API_KEY` value around only for the duration of the request.
3. Use the bundled wrapper instead of inline `security` commands when possible:

```bash
scripts/run_with_openai_guard.sh gpt-5.1 512 -- codex exec --prompt "Explain the repo"
```

The wrapper validates the requested model/tokens, exposes `OPENAI_API_KEY` only when the quota allows it, and unsets the key immediately after the wrapped command completes.

4. If a request would exceed the free-tier limit, the helper aborts and explains how many tokens remain and which bucket rejected it.

Rinse and repeat daily; the helper keeps usage durable in `~/.codex/openai_quota.json` and resets at midnight UTC.
