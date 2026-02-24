# Database Patterns

How to query and modify MANTL data via psql for browser testing.

## Connecting

```bash
psql  # default local connection works
```

## Key Tables & Databases

### console-api database (`cao`)

**Clients (tenants):**
```sql
-- Find a client by name
SELECT id, name FROM cao.client WHERE name ILIKE '%neue%';

-- Get full client config (large JSON)
SELECT data FROM cao.client_config WHERE client_id = '<client-id>' ORDER BY version DESC LIMIT 1;
```

**Accounts:**
```sql
-- Find accounts for a client, newest first
SELECT id, fields->>'productId' AS product, created_at
FROM cao.account
WHERE client_id = '<client-id>'
ORDER BY created_at DESC
LIMIT 5;

-- Get account details including product snapshot
SELECT id, fields, application_id
FROM cao.account
WHERE id = '<account-id>';
```

**Applications:**
```sql
-- Find the application for an account
SELECT id, status, fields
FROM cao.application
WHERE id = '<application-id>';
```

## Client Config Structure

Client config is stored as JSON in `cao.client_config.data`. Key paths:

```
data.products.<productId>.optionalServiceIds[]   -- services available to a product
data.products.<productId>.requiredServiceIds[]    -- services required for a product
data.services.<serviceId>.type                     -- service type (e.g. "beneficiary", "beneficiariesWithSignatures")
data.services.<serviceId>.label                    -- display label
```

### Reading config sections with psql

```sql
-- List all service IDs and their types
SELECT
  key AS service_id,
  value->>'type' AS service_type,
  value->>'label' AS label
FROM cao.client_config cc,
  jsonb_each(cc.data->'services')
WHERE cc.client_id = '<client-id>'
ORDER BY cc.version DESC
LIMIT 20;

-- Check which services a product references
SELECT
  data->'products'->'<productId>'->'optionalServiceIds' AS optional,
  data->'products'->'<productId>'->'requiredServiceIds' AS required
FROM cao.client_config
WHERE client_id = '<client-id>'
ORDER BY version DESC
LIMIT 1;
```

### Modifying config with psql

**WARNING:** Config changes only affect new accounts. Existing accounts read from a `productSnapshot` baked into the account/application at booking time.

```sql
-- Add a service ID to a product's optionalServiceIds
UPDATE cao.client_config
SET data = jsonb_set(
  data,
  '{products,<productId>,optionalServiceIds}',
  (data->'products'->'<productId>'->'optionalServiceIds') || '"<serviceId>"'::jsonb
)
WHERE client_id = '<client-id>'
  AND version = (SELECT MAX(version) FROM cao.client_config WHERE client_id = '<client-id>');

-- Update a service's type field
UPDATE cao.client_config
SET data = jsonb_set(
  data,
  '{services,<serviceId>,type}',
  '"<newType>"'
)
WHERE client_id = '<client-id>'
  AND version = (SELECT MAX(version) FROM cao.client_config WHERE client_id = '<client-id>');
```

After modifying config, you **must** fire a Kafka `client.updates` event to invalidate caches across all services. Without this, services like console-api will continue serving stale config.

### Firing the cache invalidation event

The Kafka broker runs in Docker (`broker` container) on port 29092. The event payload is `{ clientId, version }`:

```bash
# Get the client ID and latest version first via psql, then:
docker exec broker kafka-console-producer.sh \
  --bootstrap-server broker:29092 \
  --topic client.updates \
  <<< '{"clientId":"<client-id>","version":<version>}'
```

This triggers `ClientHttpService.deleteFromCache(clientId)` in every service that uses `nest-core`'s Kafka cache management (which is most of them).

**Alternative (less reliable):** Restart services manually via pm2:
```bash
pm2 restart console-api client-service
```
This works but only clears caches for the restarted services. The Kafka event propagates to all consumers.

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
