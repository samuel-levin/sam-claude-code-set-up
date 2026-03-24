#!/bin/bash
# Prepare beneficiary services in local client config for development/testing.
#
# Adds the beneficiariesWithSignatures service definition (if missing),
# then configures two products:
#   - consumerChecking: 'beneficiary' as a requiredServiceId
#   - consumerSavings:  'beneficiariesWithSignatures' as an optionalServiceId
#   - attestationTypes: 'acceptBeneficiary' with qualifyingScopes ['hasBeneficiary']
#
# Usage: prepare_beneficiary_services.sh [client_id]
#   client_id defaults to d66b0704-1e05-4af1-bb6a-7da565b484fa

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLIENT_ID="${1:-d66b0704-1e05-4af1-bb6a-7da565b484fa}"

echo "Preparing beneficiary services for client: $CLIENT_ID"

# 1. Add beneficiariesWithSignatures service definition
echo "Adding beneficiariesWithSignatures service definition..."
bash "$SCRIPT_DIR/update_client_config.sh" "$CLIENT_ID" '{
  "services": {
    "beneficiariesWithSignatures": {
      "id": "beneficiariesWithSignatures",
      "name": "Beneficiaries With Signatures",
      "type": "beneficiariesWithSignatures",
      "autoApply": false,
      "automated": false,
      "disclosure": "",
      "description": "Add beneficiaries with signatures to account",
      "confirmation": "",
      "maximumBeneficiaries": 10
    }
  }
}'

# 2. Add 'beneficiary' as a requiredServiceId on consumerChecking
echo "Adding beneficiary to consumerChecking.requiredServiceIds..."
bash "$SCRIPT_DIR/update_client_config.sh" "$CLIENT_ID" '{
  "products": {
    "consumerChecking": {
      "requiredServiceIds": ["beneficiary"]
    }
  }
}'

# 3. Read current consumerSavings optionalServiceIds and append beneficiariesWithSignatures
echo "Adding beneficiariesWithSignatures to consumerSavings.optionalServiceIds..."

export PGPASSWORD=mantl
PSQL="psql -h localhost -U mantl -d mantl -t -A"

CURRENT_OPTIONAL=$($PSQL -c "SELECT data->'products'->'consumerSavings'->'optionalServiceIds' FROM client_service.client WHERE id = '$CLIENT_ID'")

# Check if beneficiariesWithSignatures is already present
if echo "$CURRENT_OPTIONAL" | jq -e 'index("beneficiariesWithSignatures")' >/dev/null 2>&1; then
  echo "beneficiariesWithSignatures already in consumerSavings.optionalServiceIds, skipping"
else
  UPDATED_OPTIONAL=$(echo "$CURRENT_OPTIONAL" | jq '. + ["beneficiariesWithSignatures"]')
  bash "$SCRIPT_DIR/update_client_config.sh" "$CLIENT_ID" "{\"products\":{\"consumerSavings\":{\"optionalServiceIds\":$UPDATED_OPTIONAL}}}"
fi

# 4. Add 'acceptBeneficiary' attestation with hasBeneficiary qualifying scope
echo "Adding acceptBeneficiary attestation type..."
bash "$SCRIPT_DIR/update_client_config.sh" "$CLIENT_ID" '{
  "attestationTypes": {
    "acceptBeneficiary": {
      "title": "Accept Beneficiary",
      "copy": "You'\''ve agreed to add a beneficiary",
      "isDisplayedAsCheckboxInSelfServe": true,
      "qualifyingScopes": ["hasBeneficiary"]
    }
  }
}'

echo ""
echo "Done! Config now has:"
echo "  - services.beneficiariesWithSignatures defined"
echo "  - consumerChecking.requiredServiceIds includes 'beneficiary'"
echo "  - consumerSavings.optionalServiceIds includes 'beneficiariesWithSignatures'"
echo "  - attestationTypes.acceptBeneficiary with qualifyingScopes ['hasBeneficiary']"
