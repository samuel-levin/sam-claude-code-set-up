#!/bin/bash
# Build a specific MANTL package or service
# Usage: build.sh <package-name>
#
# Examples:
#   build.sh client-config
#   build.sh constants
#   build.sh console-api

set -euo pipefail

PACKAGE="${1:?Usage: build.sh <package-name>}"

pnpm turbo --filter="@mantl/$PACKAGE" build
