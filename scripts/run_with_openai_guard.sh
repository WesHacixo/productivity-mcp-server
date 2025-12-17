#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <model> <tokens> -- <command...>"
  exit 1
fi

model="$1"
shift
tokens="$1"
shift

if [[ "$1" != "--" ]]; then
  echo "Expected '--' before the command to run"
  exit 1
fi
shift

guard_cmd=(scripts/openai_quota_guard.py request --model "$model" --tokens "$tokens")
"${guard_cmd[@]}"

api_key=$(security find-generic-password -s "openai-api-key" -w)
export OPENAI_API_KEY="$api_key"
"$@"
status=$?
unset OPENAI_API_KEY
exit $status
