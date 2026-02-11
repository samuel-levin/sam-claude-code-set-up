# Client Configuration

## Overview

X-Darwin is a SaaS platform where each client has a highly flexible, customizable configuration. The entire system is driven by a massive JSON object that contains all unique configurations for each client.

## Storage

**Location:** `ClientService.client` table, `data` column

The client configuration is stored as a JSON object in the database. This single object controls:
- Product definitions
- Branding and UI customization
- Workflow rules
- Feature flags
- Integration settings
- Field configurations
- And much more

## Type System

**Package:** `@mantl/client-config-typings`

This package defines the TypeScript types for the entire configuration object. Any field that can exist in client config must have a type definition here.

**Important:** Changes to types require versioning (see [client-config-versioning.md](client-config-versioning.md))

## How It's Used

(Build this out as you discover patterns)

### In Console-API (BFF)

- Services fetch config via `clientService().get()`
- Config passed to business logic and validation
- DBMProductService uses config for product operations

### In Console-Web (Frontend)

- Relay queries fetch config via GraphQL
- Custom scalar mappings in `relay.config.js`:
  - `DBM_FullClientConfigJSONObject` → `ClientConfiguration`
  - `ClientConfigAccountVariantJSONObject` → `AccountVariant`
  - And many more domain-specific types

### In Microservices

- Each service receives `clientId` in requests
- Services fetch config as needed for validation and business rules

## Configuration Versioning

When making changes to the configuration schema, you must follow the versioning workflow.

**See:** [client-config-versioning.md](client-config-versioning.md) for the complete process.

## Common Patterns

(Add as discovered)

### Accessing Config in Resolvers

```typescript
const clientService = CAO.clientService()
const client = await clientService.get()
const config = client.fullConfig
```

### Config Validation

**CRITICAL RULE:** Types and validation schemas must stay in sync.

Validation schemas live in `@mantl/client-config` package:
- Current schema: `src/validation/current-schema/`
- Locked schemas: Generated per version

**Why this matters:** Client configs are validated when passed to client-service. If types and validation schemas don't match, configs will fail validation at runtime.

**Technologies used:**
- Services: JSON Schema (AJV) - `services.ts`
- Products: TypeBox - `products.ts`

**When making config changes:**
1. Update types in `packages/client-config-typings/src/`
2. Update validation in `packages/client-config/src/validation/current-schema/`
3. Ensure field names and structures match exactly

## Key Files

| Location | Purpose |
|----------|---------|
| `packages/client-config-typings/` | TypeScript type definitions |
| `packages/client-config/src/validation/current-schema/` | Current validation schema |
| `packages/constants/src/clientConfiguration.ts` | `CONFIG_SCHEMA_VERSION` constant |
| `src/client-service/db/seeds-versioning/` | Versioning seeds for migrations |
| `src/client-service/src/modules/client/` | Client service (storage) |

## Related Documentation

- [Client Config Versioning Workflow](client-config-versioning.md) - How to create new versions
- [Console-API Patterns](console-api-patterns.md) - How config flows through BFF
- [BFF-Microservice Communication](bff-microservice-communication.md) - How clientId is scoped
