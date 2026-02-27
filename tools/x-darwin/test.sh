#!/bin/bash
# Run tests for a MANTL service
# Usage: test.sh <service-name> [test-file-pattern]
#
# Examples:
#   test.sh console-api
#   test.sh application-service
#   test.sh console-api path/to/file.spec.ts
#   test.sh core-wrapper-service some-adapter.spec
#   test.sh console-web CDASOBeneficiaryRequiredActions   # uses test:unit
#   test.sh web-automation v3/console/tests/someTest.ts   # requires full path from service root

set -euo pipefail

SERVICE="${1:?Usage: test.sh <service-name> [test-file-pattern]}"
PATTERN="${2:-}"

# Service-specific test commands:
#   web-automation → console:e2e-dev (testcafe), pattern must be full path from service root
#   console-web   → test:unit
#   everything else → test (jest)
case "$SERVICE" in
  web-automation) TEST_CMD="console:e2e-dev" ;;
  console-web)    TEST_CMD="test:unit" ;;
  *)              TEST_CMD="test" ;;
esac

if [ -z "$PATTERN" ]; then
  pnpm --filter="@mantl/$SERVICE" $TEST_CMD
else
  pnpm --filter="@mantl/$SERVICE" $TEST_CMD $PATTERN
fi
