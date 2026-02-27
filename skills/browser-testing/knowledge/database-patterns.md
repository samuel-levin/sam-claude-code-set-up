# Database Patterns

How to query and modify MANTL data via psql for browser testing.

## Default Client

Always use client ID `d66b0704-1e05-4af1-bb6a-7da565b484fa` unless explicitly directed otherwise.

## Connecting

PostgreSQL runs in Docker container `tooling-postgres-1` with credentials `mantl`/`mantl` and database `mantl`.

```bash
# All queries must be run via docker exec
docker exec tooling-postgres-1 psql -U mantl -d mantl -t -A -c "<SQL>"
```

## Key Tables

All tables are in the `client_service` schema. There is NO separate `cao` schema for client/config data.

- `client_service.client` — clients (tenants), config stored in `data` JSONB column
- `client_service.client.data` — the full client config JSON (services, products, fields, features)

**There is NO `client_config` table.** Config lives directly on the `client` table in the `data` column.

**Clients (tenants):**
```sql
-- Find a client by name
SELECT id, name FROM client_service.client WHERE name ILIKE '%search%';

-- Get full client config (large JSON)
SELECT data FROM client_service.client WHERE id = '<client-id>';
```

**Accounts:**
```sql
-- Find accounts for a client, newest first
SELECT id, fields->>'productId' AS product, created_at
FROM client_service.account
WHERE client_id = '<client-id>'
ORDER BY created_at DESC
LIMIT 5;

-- Get account details including product snapshot
SELECT id, fields, application_id
FROM client_service.account
WHERE id = '<account-id>';
```

**Applications:**
```sql
-- Find the application for an account
SELECT id, status, fields
FROM client_service.application
WHERE id = '<application-id>';
```

## Client Config Structure

Client config is stored as JSON in `client_service.client.data`. Key paths:

```
data.products.<productId>.optionalServiceIds[]   -- services available to a product
data.products.<productId>.requiredServiceIds[]    -- services required for a product
data.services.<serviceId>.type                     -- service type (e.g. "beneficiary", "beneficiariesWithSignatures")
data.services.<serviceId>.name                     -- display name
```

### Reading config sections with psql

```sql
-- List all service IDs and their types
SELECT
  key AS service_id,
  value->>'type' AS service_type,
  value->>'name' AS name
FROM client_service.client c,
  jsonb_each(c.data->'services')
WHERE c.id = '<client-id>';

-- Check which services a product references
SELECT
  data->'products'->'<productId>'->'optionalServiceIds' AS optional,
  data->'products'->'<productId>'->'requiredServiceIds' AS required
FROM client_service.client
WHERE id = '<client-id>';
```

### Modifying config with psql

**WARNING:** Config changes only affect new accounts. Existing accounts read from a `productSnapshot` baked into the account/application at booking time.

```sql
-- Add a service ID to a product's optionalServiceIds
UPDATE client_service.client
SET data = jsonb_set(
  data,
  '{products,<productId>,optionalServiceIds}',
  (data->'products'->'<productId>'->'optionalServiceIds') || '"<serviceId>"'::jsonb
)
WHERE id = '<client-id>';

-- Update a service's type field
UPDATE client_service.client
SET data = jsonb_set(
  data,
  '{services,<serviceId>,type}',
  '"<newType>"'
)
WHERE id = '<client-id>';
```

### Modifying config with MCP tool

The `update_client_config` MCP tool can deep-merge JSON into the config and fires Kafka cache invalidation automatically:

```
mcp__x-darwin-tools__update_client_config(client_id, update_json)
```

### Firing the cache invalidation event (manual psql changes only)

After modifying config via psql, you **must** fire a Kafka `client.updates` event to invalidate caches across all services. The MCP tool does this automatically.

The Kafka broker runs in Docker (`broker` container) on port 29092:

```bash
docker exec broker kafka-console-producer.sh \
  --bootstrap-server broker:29092 \
  --topic client.updates \
  <<< '{"clientId":"<client-id>"}'
```

**Alternative (less reliable):** Restart services manually via pm2:
```bash
pm2 restart console-api client-service
```

## Product Snapshot Gotcha

After an account is booked, the system reads service availability from a **product snapshot** stored in the application/account — NOT the live client config. This means:

- Updating live config does NOT affect existing accounts
- To test config changes on accounts, you need to create a **new** account after updating the config
- Or, directly update the snapshot in the account's `fields` (more complex, less realistic)

## Relay IDs

MANTL console URLs use Relay global IDs (base64-encoded). To construct one:

```bash
# Format: base64("entityType:entityId")
echo -n "cao_account:<account-uuid>" | base64
# Use this in URLs: /console/customers/accounts/<relay-id>
```

Entity type prefixes:
- Accounts: `cao_account`
- Applications: `cao_application`
- Clients: `cao_client`
