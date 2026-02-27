#!/bin/bash
# Run TypeScript type checking
# Usage: typecheck.sh [service-name]
#
# Without arguments: runs type-check across the entire monorepo
# With argument: runs type-check for a specific service/package
#
# Examples:
#   typecheck.sh                  # whole monorepo
#   typecheck.sh console-api
#   typecheck.sh client-config

set -euo pipefail

SERVICE="${1:-}"

if [ -z "$SERVICE" ]; then
  pnpm type-check
else
  pnpm --filter="@mantl/$SERVICE" type-check
fi
