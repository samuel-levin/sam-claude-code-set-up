#!/bin/bash
# Apply a partial update to a client config via deep merge
# Usage: update_client_config.sh <client_id> '<json_partial>'
#
# Reads the current config from client_service.client in the mantl database,
# deep merges the provided JSON partial, writes it back, and fires a Kafka
# cache invalidation event.
#
# Examples:
#   update_client_config.sh abc-123 '{"products":{"checking":{"name":"New Name"}}}'

set -euo pipefail

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required. Install with: brew install jq"; exit 1; }

CLIENT_ID="${1:?Usage: update_client_config.sh <client_id> '<json_partial>'}"
PARTIAL="${2:?Usage: update_client_config.sh <client_id> '<json_partial>'}"

# DB connection
export PGPASSWORD=mantl
PSQL="psql -h localhost -U mantl -d mantl -t -A"

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

# Write back using dollar-quoting to safely handle any JSON content
$PSQL -c "UPDATE client_service.client SET data = \$json\$${MERGED}\$json\$::jsonb WHERE id = '${CLIENT_ID}'"

echo "Config updated for client: $CLIENT_ID"

# Fire Kafka cache invalidation event
docker exec broker kafka-console-producer.sh \
  --bootstrap-server broker:29092 \
  --topic client.updates \
  <<< "{\"clientId\":\"${CLIENT_ID}\"}"

echo "Cache invalidation event sent"
