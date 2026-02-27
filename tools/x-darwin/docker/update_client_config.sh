#!/bin/bash
# Container version of update_client_config.sh (DB operations only)
# Runs inside Docker on the llm-sandbox network.
# Kafka cache bust is handled by the host-side MCP server after this exits.

set -euo pipefail

CLIENT_ID="${1:?Usage: update_client_config.sh <client_id> '<json_partial>'}"
PARTIAL="${2:?Usage: update_client_config.sh <client_id> '<json_partial>'}"

# DB connection — uses Docker DNS to resolve tooling-postgres-1
export PGPASSWORD=mantl
PSQL="psql -h tooling-postgres-1 -U mantl -d mantl -t -A"

# Validate that partial is valid JSON
echo "$PARTIAL" | jq . >/dev/null 2>&1 || { echo "ERROR: Second argument is not valid JSON"; exit 1; }

# Read current config
CURRENT=$($PSQL -c "SELECT data FROM client_service.client WHERE id = '$CLIENT_ID'")

if [ -z "$CURRENT" ]; then
  echo "ERROR: No client found with id: $CLIENT_ID"
  exit 1
fi

# Deep merge: current * partial (partial wins on conflicts)
MERGED=$(jq -s '.[0] * .[1]' <(echo "$CURRENT") <(echo "$PARTIAL"))

# Write back by piping SQL through stdin to avoid argument length limits
echo "UPDATE client_service.client SET data = \$json\$${MERGED}\$json\$::jsonb WHERE id = '${CLIENT_ID}'" | $PSQL

echo "Config updated for client: $CLIENT_ID"
