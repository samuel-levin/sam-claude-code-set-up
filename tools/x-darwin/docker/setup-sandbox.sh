#!/bin/bash
# Ensure the llm-sandbox network exists and dev containers are connected.
# Safe to run multiple times — skips anything already in place.
# Run after Docker restarts or when first setting up.

set -euo pipefail

NETWORK="llm-sandbox"
CONTAINERS=("tooling-postgres-1" "broker")

# Create network if it doesn't exist
if ! docker network inspect "$NETWORK" >/dev/null 2>&1; then
  docker network create --internal "$NETWORK"
  echo "Created internal network: $NETWORK"
else
  echo "Network $NETWORK already exists"
fi

# Connect containers if not already connected
for container in "${CONTAINERS[@]}"; do
  if docker inspect "$container" --format "{{json .NetworkSettings.Networks}}" 2>/dev/null | grep -q "$NETWORK"; then
    echo "$container already on $NETWORK"
  else
    if docker inspect "$container" >/dev/null 2>&1; then
      docker network connect "$NETWORK" "$container"
      echo "Connected $container to $NETWORK"
    else
      echo "WARNING: $container not running — skipped"
    fi
  fi
done

echo "Sandbox ready"
