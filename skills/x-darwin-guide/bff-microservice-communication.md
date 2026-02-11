# BFF → Microservice Communication

## Architecture Overview

Console-API (BFF) orchestrates calls to microservices using:
- HTTP transport via `@mantl/transport-http-client`
- Service proxy pattern with actor injection
- Request-scoped services with clientId/viewerId context
- CAO (Client-scoped Application Objects) pattern

## Request Flow

```
HTTP Request
  ↓
Middleware: Extract clientId, viewerId from token
  ↓
Middleware: Create scoped services with context
  ↓
GraphQL: Expose services in rootValue.CAO
  ↓
Resolver: Call service methods
  ↓
Service: Add clientId to payload, actor to headers
  ↓
HTTP POST to microservice
  ↓
Microservice: Validate actor, process with clientId
```

## Service Proxy Pattern

**Location:** `src/console-api/src/cao/services/ServiceProxy.ts`

```typescript
const serviceProxy = <T>(service: ClassOf<T>, viewerId?: string): T => {
  return new service(logger).setActor(getActor(viewerId))
}

const getActor = (viewerId?: string): common.IActor => ({
  id: viewerId,
  type: viewerId ? ActorType.ADMIN : ActorType.SYSTEM,
  experience: ActorExperience.CONSOLE,
})
```

**What it does:**
- Wraps HTTP client from `@mantl/transport-http-client`
- Injects `x-mantl-actor` header with JSON actor object
- Sets actor context for distributed tracing

## Service Wrapper Pattern

Each service is a factory function:

```typescript
const AccountService = ({
  clientId,
  viewerId,
}: ClientScopedServiceArgs): IAccountService => {
  const service = serviceProxy(AccountHttpService, viewerId)

  return {
    create(args) {
      return service
        .create({ clientId, ...args })  // clientId always included
        .then(parseAccountResponse)
    },
    getById(id) {
      return service
        .getById({ clientId, id })
        .then(parseAccountOptResponse)
    },
  }
}
```

**Key Points:**
- `clientId` injected into every request body
- Actor automatically in headers via proxy
- Response parsing standardized
- Error handling consistent

## Middleware: clientScopedServices

**Location:** `src/console-api/src/_base/middleware/clientScopedServices.ts`

Creates all services at request start:

```typescript
const services: IClientScopedServices = {
  accountService: once(() => AccountService({ clientId, viewerId })),
  clientService: once(() => HttpClientService({ clientId, viewerId })),
  // ... 20+ more services
}

req.locals.services = services
```

**Why `_.once()`?**
- Services expensive to instantiate
- Creates HTTP client, sets up headers
- Each service called once per request, cached thereafter
- Multiple resolver calls share same service instance

## GraphQL Context Setup

**Location:** `src/console-api/src/_base/middleware/graphqlRootHandler.ts`

```typescript
rootValue: {
  clientId: locals.clientId,
  objectManager,
  CAO: { ...locals.services },  // All scoped services
  rolloutFlags: locals.rolloutFlags,
}
```

Resolvers access via:
```typescript
const { rootValue: { CAO: { accountService } } } = info
const account = await accountService().getById(id)
```

## Actor Injection

**Actor object:**
```typescript
{
  id: viewerId,
  type: ActorType.ADMIN,
  experience: ActorExperience.CONSOLE
}
```

**HTTP header:**
- Name: `x-mantl-actor`
- Value: JSON stringified actor object

**Microservice validation:**
- NestJS `ActorGuard` validates header presence
- Extracts actor for request context
- Throws `BadRequestException` if missing and required

## Request Scoping

**Every microservice call includes:**

**Headers:**
```
x-mantl-actor: {"id":"viewer-uuid","type":"admin","experience":"console"}
```

**Body:**
```json
{
  "clientId": "client-uuid",
  "updatedBy": "viewer-uuid",
  ...args
}
```

## Service Isolation

**Per-Request:**
- New ObjectManager instance
- New service instances (via middleware)
- Isolated context, no shared state
- Thread-safe execution

## DataLoader Batching

Services use DataLoader for efficiency:

```typescript
getById: new DataLoader<string, ClientType>(async ids => {
  const responses = await batchQueryFn(ids, async id =>
    service.get({ clientId: id, hydrate: true })
  )
  return responses.map(parseClientResponse)
})
```

Multiple `clientService().get()` calls in same request → single HTTP call.

## Error Handling

**Response parser** (`responseParser.ts`) transforms service responses:
- `ServiceStatusResponse.OK` → Return data
- `ServiceStatusResponse.NOT_FOUND` → null or NotFoundError
- `ServiceStatusResponse.INELIGIBLE` → Throw with reasons
- `ServiceStatusResponse.INVALID_ARGUMENT` → Validation error
- Other → Log and throw

## Key Files

| File | Purpose |
|------|---------|
| `clientScopedServices.ts` | Creates scoped services per request |
| `ServiceProxy.ts` | Wraps HTTP clients with actor injection |
| `initHandler.ts` | Extracts clientId/viewerId from token |
| `graphqlRootHandler.ts` | Sets CAO context in rootValue |
| `AbstractInternalService.ts` | HTTP client base with setActor() |
| `AccountService.ts` | Example service wrapper |
| `responseParser.ts` | Standardized response handling |
| `actor.guard.ts` (nest-core) | Validates actor on microservices |

## Critical Details

1. **All POST requests:** Microservices use POST for everything (see architecture.md)
2. **clientId everywhere:** Every microservice call includes clientId in body
3. **Actor in headers:** Identity propagated via `x-mantl-actor` as JSON
4. **Request isolation:** No shared state between requests
5. **Memoization:** Services cached per request with `_.once()`
