#!/bin/bash
# Read an application from the database.
# If an ID is provided, fetches that application.
# Otherwise, fetches the most recently created application.
# Runs inside Docker on the llm-sandbox network.

set -euo pipefail

APP_ID="${1:-}"
JQ_QUERY="${2:-.}"

# DB connection — uses Docker DNS to resolve tooling-postgres-1
export PGPASSWORD=mantl
PSQL="psql -h tooling-postgres-1 -U mantl -d mantl -t -A"

if [ -n "$APP_ID" ]; then
  ROW=$($PSQL -c "SELECT row_to_json(a) FROM application_service.application a WHERE id = '$APP_ID'")
else
  ROW=$($PSQL -c "SELECT row_to_json(a) FROM application_service.application a ORDER BY created_at DESC LIMIT 1")
fi

if [ -z "$ROW" ]; then
  echo "ERROR: No application found"
  exit 1
fi

echo "$ROW" | jq "$JQ_QUERY"
