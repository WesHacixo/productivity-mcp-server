#!/bin/sh
set -euo pipefail

if [ ! -d ".githooks" ]; then
  echo "Creating .githooks..."
  mkdir -p .githooks
fi

chmod +x .githooks/pre-commit

git config core.hooksPath .githooks

echo "git hooks configured via core.hooksPath -> .githooks"
