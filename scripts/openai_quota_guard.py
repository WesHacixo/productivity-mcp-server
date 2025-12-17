#!/usr/bin/env python3
"""Manage OpenAI free-tier usage and expose the API key only when the paid plan is depleted."""
from __future__ import annotations

import argparse
import json
import sys
import textwrap
from datetime import date
from pathlib import Path
from typing import Dict

STATE_DIR = Path.home() / ".codex"
STATE_FILE = STATE_DIR / "openai_quota.json"
DAILY_LIMITS: Dict[str, int] = {
    "tokens_250k": 250_000,
    "tokens_2_5m": 2_500_000,
}
MODEL_BUCKETS: Dict[str, str] = {
    # 250k daily tokens across these models
    "gpt-5.1": "tokens_250k",
    "gpt-5.1-codex": "tokens_250k",
    "gpt-5": "tokens_250k",
    "gpt-5-codex": "tokens_250k",
    "gpt-5-chat-latest": "tokens_250k",
    "gpt-4.1": "tokens_250k",
    "gpt-4o": "tokens_250k",
    "o1": "tokens_250k",
    "o3": "tokens_250k",
    # 2.5M daily tokens across the "mini" / "nano" models
    "gpt-5.1-codex-mini": "tokens_2_5m",
    "gpt-5-mini": "tokens_2_5m",
    "gpt-5-nano": "tokens_2_5m",
    "gpt-4.1-mini": "tokens_2_5m",
    "gpt-4.1-nano": "tokens_2_5m",
    "gpt-4o-mini": "tokens_2_5m",
    "o3-mini": "tokens_2_5m",
    "o4-mini": "tokens_2_5m",
    "codex-mini-latest": "tokens_2_5m",
}

def ensure_state_dir() -> None:
    STATE_DIR.mkdir(exist_ok=True)

def today_str() -> str:
    return date.today().isoformat()

def default_state() -> Dict:
    return {
        "date": today_str(),
        "buckets": DAILY_LIMITS.copy(),
        "plan_tokens_left": 0,
    }

def load_state() -> Dict:
    if not STATE_FILE.exists():
        return default_state()
    try:
        with STATE_FILE.open("r", encoding="utf-8") as f:
            state = json.load(f)
    except (json.JSONDecodeError, IOError):
        return default_state()
    if state.get("date") != today_str():
        preserved_plan = state.get("plan_tokens_left", 0)
        state = default_state()
        state["plan_tokens_left"] = preserved_plan
    state.setdefault("buckets", DAILY_LIMITS.copy())
    for bucket, limit in DAILY_LIMITS.items():
        state["buckets"].setdefault(bucket, limit)
    state.setdefault("plan_tokens_left", 0)
    return state

def save_state(state: Dict) -> None:
    ensure_state_dir()
    state["date"] = today_str()
    with STATE_FILE.open("w", encoding="utf-8") as f:
        json.dump(state, f, indent=2)

def bucket_for_model(model: str) -> str | None:
    return MODEL_BUCKETS.get(model)

def print_allowlist() -> None:
    small = [m for m, bucket in MODEL_BUCKETS.items() if bucket == "tokens_250k"]
    mini = [m for m, bucket in MODEL_BUCKETS.items() if bucket == "tokens_2_5m"]
    print("250k-token models (per day):")
    print("  " + ", ".join(sorted(small)))
    print("2.5M-token models (per day):")
    print("  " + ", ".join(sorted(mini)))

def cmd_status(args: argparse.Namespace) -> int:
    state = load_state()
    print(f"Date: {state['date']}")
    print(f"Plan tokens left: {state['plan_tokens_left']}")
    for bucket, remaining in state["buckets"].items():
        limit = DAILY_LIMITS.get(bucket, remaining)
        print(f"{bucket}: {remaining} tokens remaining of {limit}")
    if args.allowlist:
        print()
        print_allowlist()
    return 0

def cmd_set_plan(args: argparse.Namespace) -> int:
    if args.tokens < 0:
        print("Plan tokens cannot be negative", file=sys.stderr)
        return 1
    state = load_state()
    state["plan_tokens_left"] = args.tokens
    save_state(state)
    print(f"Set plan tokens left to {args.tokens}")
    return 0

def cmd_reset(args: argparse.Namespace) -> int:
    state = default_state()
    prev = load_state()
    state["plan_tokens_left"] = prev.get("plan_tokens_left", 0)
    save_state(state)
    print("Token buckets reset to daily limits")
    return 0

def cmd_request(args: argparse.Namespace) -> int:
    model = args.model.strip().lower()
    state = load_state()
    if state.get("plan_tokens_left", 0) > 0:
        print("Plan tokens still available; continue using your plan before hitting OpenAI.")
        return 1
    bucket = bucket_for_model(model)
    if bucket is None:
        print(f"Model '{model}' is not on the free-tier allowlist. Use one of these:")
        print_allowlist()
        return 1
    if args.tokens <= 0:
        print("Requested token count must be positive", file=sys.stderr)
        return 1
    remaining = state["buckets"].get(bucket, 0)
    if args.tokens > remaining:
        print(
            f"Not enough tokens remaining in {bucket} ({remaining} left, {args.tokens} requested)",
            file=sys.stderr,
        )
        return 1
    state["buckets"][bucket] = remaining - args.tokens
    save_state(state)
    print("✅ OpenAI free-tier guard allowed this request.")
    print(f"Tokens consumed: {args.tokens}; {state['buckets'][bucket]} remaining in {bucket}.")
    print()
    print("Run the following to expose the key, then make your OpenAI call:")
    print("  export OPENAI_API_KEY=\"$(security find-generic-password -s 'openai-api-key' -w)\"")
    return 0

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Guard OpenAI free-tier usage and keep the API key idle until your paid plan is drained.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=textwrap.dedent(
            """
            Commands:
              status            show remaining tokens and plan status
              set-plan          set how many plan tokens remain before falling back to OpenAI
              reset             reset daily buckets (date auto-reset happens by default)
              request           check a request before using the OpenAI key
            """
        ),
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    status_parser = subparsers.add_parser("status", help="Show current token and plan state")
    status_parser.add_argument("--allowlist", action="store_true", help="Also print the allowed models")
    status_parser.set_defaults(func=cmd_status)

    plan_parser = subparsers.add_parser("set-plan", help="Update the remaining paid-plan tokens")
    plan_parser.add_argument("tokens", type=int, help="Tokens left on the paid plan")
    plan_parser.set_defaults(func=cmd_set_plan)

    reset_parser = subparsers.add_parser("reset", help="Reset daily bucket counts")
    reset_parser.set_defaults(func=cmd_reset)

    req_parser = subparsers.add_parser("request", help="Validate a request before exposing the OpenAI key")
    req_parser.add_argument("--model", required=True, help="Model name (lowercase, e.g. gpt-5.1)")
    req_parser.add_argument("--tokens", type=int, required=True, help="Estimated token usage for the request")
    req_parser.set_defaults(func=cmd_request)

    args = parser.parse_args()
    return getattr(args, "func")(args)

if __name__ == "__main__":
    raise SystemExit(main())
