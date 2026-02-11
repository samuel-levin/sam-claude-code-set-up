# Console-API (BFF) Patterns

## GraphQL Architecture

Console-API is a GraphQL BFF organized by business domain.

### Directory Structure

```
src/console-api/src/
├── cao/graphql/           # Customer Account Opening
│   ├── resolver/          # 149 field resolvers
│   ├── mutation/          # 125 mutations
│   └── type/              # 127 type definitions
├── dbm/graphql/           # Digital Branch Manager
│   ├── query/
│   ├── resolver/          # 40+ resolvers
│   ├── mutation/          # 50+ mutations
│   └── type/              # 48 types
├── tenant/graphql/        # Tenant/client management
├── user/graphql/          # User operations
└── _base/graphql/         # Shared infrastructure
```

### Resolver Pattern

**Field Resolvers** - Access services from CAO context:

```typescript
const AccountResolver: GraphQLFieldResolver = async (
  _parent,
  args,
  context,
  { rootValue: { CAO } }
) => {
  const { accountService } = CAO
  const account = await accountService().getById(id)
  return account
}
```

**Key Points:**
- Services extracted from `rootValue.CAO`
- Services are functions wrapped with `_.once()` - must be called: `accountService()`
- Services are request-scoped and memoized

### Mutation Pattern

Uses `mutationWithClientMutationId` wrapper:

```typescript
const AddBusiness = mutationWithClientMutationId({
  name: 'AddBusiness',
  inputFields: { /* input types */ },
  outputFields: { /* return types */ },
  mutateAndGetPayload: async (fields, _context, { rootValue: { CAO } }) => {
    const { businessService } = CAO
    const business = await businessService().create(fields)
    return { business }
  },
})
```

**Registration:** All mutations imported in `_configuration/base-server/graphql/_mutations.ts` (200+ mutations)

### Service Injection via CAO Context

**Middleware Flow:**
1. `clientScopedServices.ts` - Creates all services with `{ clientId, viewerId }`
2. Services wrapped with `_.once()` for memoization
3. `graphqlRootHandler.ts` - Exposes services in `rootValue.CAO`
4. Resolvers access services from CAO context

**Service Access:**
```typescript
const { accountService, applicationService } = CAO
const account = await accountService().getById(id)
```

### Domain Organization

**CAO** - Customer Account Opening (32 services)
- Account, Application, Business, Person, Document, Signature, KYC, PDF

**DBM** - Digital Branch Manager
- Client configuration, products, branding, regions, compliance

**Tenant** - Client/tenant management

**User** - User operations and permissions

### Query Root Nodes

- `Viewer` - User-scoped data
- `Console` - Admin console data
- `CAO` - Customer account opening
- `System` - System-level (admins only)
- `DBMv3` - Configuration management
- `CSM` - Client settings

### Connection/Pagination

Uses graphql-relay utilities:
```typescript
return connectionFromArray(results, args)
```

All connections include `totalItems` field.

### Type Factory Pattern

Automatic field generation:
- ID fields via `generateIdFields()`
- Timestamp fields via `generateTimestampFields()`
- ACL codes for permissions
- Interface implementations

### Authorization

Each mutation/query has:
- `code` - ACL code for permission checking
- `whitelisted` - Bypass ACL if true
- `allowedUserStatus` - User status requirements
- `permission` - Custom permission logic
