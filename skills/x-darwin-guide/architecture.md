# X-Darwin Architecture

## Overview

X-Darwin is a **monorepo of microservices** built with NestJS.

## High-Level Architecture

```
┌─────────────────┐
│   Front Ends    │
│  (2 instances)  │
└────────┬────────┘
         │
┌────────┴────────────────────┐
│         BFFs                 │
│  (Orchestration Layers)      │
│                              │
│  • Console BFF               │
│    (for bankers)             │
│                              │
│  • Self-Serve BFF            │
│    (for applicants)          │
└────────┬─────────────────────┘
         │
┌────────┴────────────────────┐
│    Microservices             │
│    (NestJS services)         │
│                              │
│  • client-service            │
│  • account-service           │
│  • loan-service              │
│  • etc...                    │
└──────────────────────────────┘
```

## Monorepo Structure

- **Microservices**: NestJS-based services located in `src/`
- **BFFs (Backend for Frontend)**:
  - **Console BFF** (`src/console-api/`): Orchestration layer for banker-facing UI
  - **Self-Serve BFF** (`src/self-serve-api/`): Orchestration layer for applicant-facing UI
- **Front Ends**: Two separate front-end applications

## Build and Run Commands

**CRITICAL:** Always run commands from the repository root, never `cd` into specific packages.

- Build specific service: `pnpm --filter=@mantl/account-service build`
- Build specific package: `pnpm --filter=@mantl/transport-http-typings build`
- Run tests: `pnpm --filter=@mantl/account-service test`
- Run service: `pnpm --filter=@mantl/account-service start:dev`

## API Routing Pattern

### CRITICAL: All APIs are POST requests

**Every endpoint in the backend uses POST**, regardless of operation type (create, read, update, delete).

### NestJS Module Pattern

Each microservice follows this structure:

```
service-name/
├── src/
│   └── modules/
│       └── feature/
│           ├── feature.module.ts       # Registers controllers, services, imports
│           ├── controllers/
│           │   └── feature.controller.ts
│           ├── services/
│           │   └── feature.service.ts
│           ├── entities/
│           └── repositories/
```

### Controller Pattern

Example from `client-service/src/modules/client/controllers/client.controller.ts`:

```typescript
@Controller({ path: 'client', scope: Scope.REQUEST })
export class ClientController {
  constructor(private readonly clientService: ClientService) {}

  @Post('create')      // POST /client/create
  @HttpCode(200)
  public async create(@Body(new JoiValidationPipe(schema)) data: IRequest) {
    const result = await this.clientService.create(data)
    return { result: OkResult(), ...result }
  }

  @Post('get')         // POST /client/get (not GET!)
  @HttpCode(200)
  public async get(@Body(new JoiValidationPipe(schema)) data: IRequest) {
    const result = await this.clientService.get(data)
    return { result: OkResult(), ...result }
  }

  @Post('update')      // POST /client/update
  @HttpCode(200)
  public async update(@Body(new JoiValidationPipe(schema)) data: IRequest) {
    const result = await this.clientService.update(data)
    return { result: OkResult(), ...result }
  }

  @Post('delete')      // POST /client/delete (not DELETE!)
  @HttpCode(200)
  public async delete(@Body(new JoiValidationPipe(schema)) data: IRequest) {
    const result = await this.clientService.delete(data)
    return { result: OkResult(), ...result }
  }
}
```

### Key Characteristics

- **All routes are POST**: Even reads, deletes, and other traditionally non-POST operations
- **All return 200**: Every endpoint uses `@HttpCode(200)`
- **Request validation**: `JoiValidationPipe` validates request bodies
- **Standard response format**: All responses include `result: OkResult()` plus data
- **Controller path + method name**: Routes follow pattern `/{controller-path}/{method-name}`
  - Example: `POST /client/get`, `POST /client/list`, `POST /client/create`

### Module Structure

From `client.module.ts`:

```typescript
@Module({
  providers: [
    ClientService,        // Business logic
    // Other services, repositories, workers...
  ],
  controllers: [
    ClientController,     // Handles routes
    // Other controllers...
  ],
  imports: [
    // Other modules, TypeORM, Redis, Kafka, etc.
  ],
  exports: [ClientService],  // Exposed to other modules
})
export class ClientModule {}
```

## Common Patterns

- **Thin controllers, fat services**: Controllers delegate all business logic to services
- **Request-scoped controllers**: `scope: Scope.REQUEST` for per-request instances
- **Validation pipes**: JoiValidationPipe validates all incoming requests
- **Standard responses**: All endpoints return `{ result: OkResult(), ...data }`

## Dependencies Between Services

(Add as discovered)
