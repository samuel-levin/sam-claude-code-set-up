#!/bin/bash
# Read client config (or a section of it) from the database.
# Runs inside Docker on the llm-sandbox network.

set -euo pipefail

CLIENT_ID="${1:?Usage: read_client_config.sh <client_id> [jq_query]}"
JQ_QUERY="${2:-.}"

# DB connection — uses Docker DNS to resolve tooling-postgres-1
export PGPASSWORD=mantl
PSQL="psql -h tooling-postgres-1 -U mantl -d mantl -t -A"

# Read current config
CURRENT=$($PSQL -c "SELECT data FROM client_service.client WHERE id = '$CLIENT_ID'")

if [ -z "$CURRENT" ]; then
  echo "ERROR: No client found with id: $CLIENT_ID"
  exit 1
fi

# Apply jq query and pretty-print
echo "$CURRENT" | jq "$JQ_QUERY"
