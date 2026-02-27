#!/bin/bash
# Restart a MANTL microservice
# Usage: restart.sh <service-name>
#
# Examples:
#   restart.sh console-api
#   restart.sh client-service
#   restart.sh application-service

set -euo pipefail

SERVICE="${1:?Usage: restart.sh <service-name>}"

pnpm --filter="@mantl/$SERVICE" dev
