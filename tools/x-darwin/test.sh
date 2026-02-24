#!/bin/bash
# Run tests for a MANTL service
# Usage: test.sh <service-name> [test-file-pattern]
#
# Examples:
#   test.sh console-api
#   test.sh application-service
#   test.sh console-api path/to/file.spec.ts
#   test.sh core-wrapper-service some-adapter.spec
#   test.sh web-automation v3/console/tests/someTest.ts   # requires full path from service root

set -euo pipefail
cd /Users/samuellevin/x-darwin

SERVICE="${1:?Usage: test.sh <service-name> [test-file-pattern]}"
PATTERN="${2:-}"

# web-automation uses console:e2e-dev (testcafe) instead of test (jest)
# Note: pattern must be a full path from the service root (e.g. v3/console/tests/file.ts)
if [ "$SERVICE" = "web-automation" ]; then
  TEST_CMD="console:e2e-dev"
else
  TEST_CMD="test"
fi

if [ -z "$PATTERN" ]; then
  pnpm --filter="@mantl/$SERVICE" $TEST_CMD
else
  pnpm --filter="@mantl/$SERVICE" $TEST_CMD $PATTERN
fi
