# Creating New Modules in Microservices

## Quick Reference: Read Example Code

Before implementing, read one complete example to understand patterns:
- **Entity:** `src/account-service/src/modules/account/entities/account.entity.ts`
- **Repository:** `src/account-service/src/modules/account/repositories/account.repository.ts`
- **Service:** `src/account-service/src/modules/account/services/account.service.ts`
- **Controller:** `src/account-service/src/modules/account/controllers/account.http.controller.ts`
- **Module:** `src/account-service/src/modules/account/account.module.ts`
- **Migration:** `src/account-service/db/migrations/1734457107922-AddCollateralTable.ts`

Read these files to understand the pattern, then follow the checklist below.

---

## Implementation Sequence & Checklist

### Phase 1: Types (packages/transport-http-typings/src/{service}/)

**Critical:** Do this first - everything depends on these types.

- [ ] Create `my-entity.ts` with interface and validation schemas
- [ ] Add response types in `response.ts`
- [ ] Export from `index.ts`
- [ ] Build: `pnpm --filter=@mantl/transport-http-typings build`

**Key patterns:**
- Use `joi.uuidReq`, `joi.stringEnumReq()`, `joi.stringOptNull` from `../common/joi`
- JSONB fields: Type as `Record<string, any>` if structure varies by client config
- All requests include `clientId: joi.uuidReq`

### Phase 2: Database (src/{service}/db/migrations/)

- [ ] Create `{timestamp}-AddMyEntityTable.ts`
- [ ] Set search_path in up() and down()
- [ ] Use `snake_case` column names, `camelCase` TypeScript
- [ ] Index `client_id` and foreign keys
- [ ] Include: id (uuid), client_id, created_at, updated_at, meta (jsonb, optional)

**Gotcha:** Use current timestamp in milliseconds for filename.

### Phase 3: Module Files (src/{service}/src/modules/{module-name}/)

Create in this order:

#### Entity (entities/my-entity.entity.ts)
- [ ] Implement interface from transport-http-typings
- [ ] Use decorators: `@Entity()`, `@PrimaryColumn()`, `@Column()`, `@Index()`, `@CreateDateColumn()`, `@UpdateDateColumn()`
- [ ] Column names match migration (snake_case in decorator)
- [ ] Use `!` for required fields, `= default` or `| null = null` for optional

**Critical gotcha:** Entities are **auto-discovered** via `ormconfig.ts` glob pattern. No manual registration needed.

#### Repository (repositories/my-entity.repository.ts)
- [ ] Extend `BaseRepository<MyEntity>`
- [ ] Use `@CustomRepository(MyEntity)` decorator
- [ ] Add custom queries: `findByClientId()`, `findByIdAndClientId()`

#### Service (services/my-entity.service.ts)
- [ ] Inject repository and logger
- [ ] Implement CRUD: create, get, update, delete
- [ ] Throw `NotFoundError` for missing entities
- [ ] Throw `InvalidArgumentError` for validation errors
- [ ] Log significant operations

#### Controller (controllers/my-entity.controller.ts)
- [ ] Path is plural noun: `@Controller({ path: 'my-entities' })`
- [ ] **ALL endpoints are `@Post()` with `@HttpCode(200)`** (critical pattern)
- [ ] Validate with `JoiValidationPipe(schema)`
- [ ] All responses include `result: OkResult()`
- [ ] Standard endpoints: `/create`, `/get`, `/update`, `/delete`, `/list`

#### Module (my-entity.module.ts)
- [ ] Register controllers
- [ ] Import `TypeOrmExModule.forCustomRepository([repositories])`
- [ ] Register services in providers
- [ ] Export services that other modules need

### Phase 4: Wire Up (src/{service}/src/)

- [ ] Import module in `app.module.ts`
- [ ] Add to imports array

### Phase 5: Build & Verify

- [ ] Build: `pnpm --filter=@mantl/{service} build`
- [ ] Fix unused imports if build fails
- [ ] Run migration: `pnpm --filter=@mantl/{service} migration:run`

---

## Critical Patterns & Gotchas

### 1. Build Commands
**ALWAYS from repository root:**
```bash
pnpm --filter=@mantl/account-service build
pnpm --filter=@mantl/transport-http-typings build
```
**NEVER:** `cd src/account-service && npm run build`

### 2. Entity Auto-Discovery
Entities are automatically found via glob pattern in `ormconfig.ts`. Just create `*.entity.ts` files in the right location.

### 3. POST-Only APIs
Every endpoint is `@Post()` with `@HttpCode(200)`, even reads and deletes. This is non-negotiable.

### 4. JSONB Fields
If field structure varies by client (controlled by client config):
```typescript
fields: Record<string, any>  // Document what it references
```

### 5. Column Naming
- Database: `snake_case` (e.g., `client_id`)
- TypeScript: `camelCase` (e.g., `clientId`)
- TypeORM maps automatically

### 6. Standard Response Format
```typescript
return {
  result: OkResult(),
  myEntity,  // or myEntities for lists
}
```

### 7. Error Patterns
```typescript
import { NotFoundError, InvalidArgumentError } from '@mantl/nest-core'

throw new NotFoundError({ message: '...', attributes: { id, clientId } })
throw new InvalidArgumentError({ message: '...', attributes: { ... } })
```

### 8. Tenant Scoping (`clientId`)
**Every entity needs `clientId`** — including join/bridge tables. `clientId` is the tenant boundary. Even if a table like `relationship_beneficiary` joins two other entities (`beneficiary` + `account`), it still gets its own `client_id` column, index, and all get/delete/update operations must scope by it. Don't substitute a related foreign key (e.g. `accountId`) for tenant scoping.

### 9. Joi Validation Runs Before Services
`JoiValidationPipe` in the controller validates requests before the service method is called. Don't duplicate Joi constraints (e.g. range checks) in the service — invalid input never reaches it.

---

## File Structure Reference

```
src/{service}/
├── db/migrations/
│   └── {timestamp}-AddMyEntityTable.ts
└── src/
    ├── app.module.ts                          (import new module here)
    └── modules/
        └── my-entity/
            ├── my-entity.module.ts
            ├── entities/
            │   └── my-entity.entity.ts
            ├── repositories/
            │   └── my-entity.repository.ts
            ├── services/
            │   └── my-entity.service.ts
            └── controllers/
                └── my-entity.controller.ts

packages/transport-http-typings/src/{service}/
├── my-entity.ts                               (interfaces & validation)
├── response.ts                                (add response types here)
└── index.ts                                   (export from here)
```

---

## Quick Validation Checklist

Before considering implementation complete:

- [ ] Types compile: `pnpm --filter=@mantl/transport-http-typings build`
- [ ] Service compiles: `pnpm --filter=@mantl/{service} build`
- [ ] Migration exists with correct timestamp
- [ ] Module imported in app.module.ts
- [ ] All endpoints are POST with @HttpCode(200)
- [ ] Entity implements interface from typings
- [ ] Repository extends BaseRepository
- [ ] Service throws proper errors
- [ ] Controller validates with JoiValidationPipe

---

## Testing Requirements

**Tests are NOT optional.** Do not report implementation as complete without addressing tests.

### Decision Process

1. **Check the Jira ticket** for explicit test requirements — honor those first
2. **Match sibling coverage** — if similar files in the same directory have tests, new files must too
3. **Use judgment on volume** — prefer fewer, meaningful tests over exhaustive coverage. Cover the happy path, key error paths, and any non-obvious branching logic. Skip trivial getter/setter tests

### What's Tested vs Not (as of the current codebase)

| Layer | Tested? | Test Location |
|-------|---------|---------------|
| Microservice handlers/services | Yes | `src/{service}/src/test/unit/` |
| Execution handlers (app-service) | Yes | `src/application-service/src/test/unit/application-execution-handlers/` |
| Execution handlers (IOI service) | Yes | `src/indication-of-interest-service/src/test/unit/indication-of-interest-execution-handlers/` |
| Transport-http-client services | No | N/A |
| HTTP controllers | No | N/A |

### Test Pattern

- Uses `@nestjs/testing` `Test.createTestingModule()` with mock providers
- Each service directory has a `helpers.ts` with shared module setup (`createUnitTestingModule`, `resolveExecuteDependencies`)
- Mock HTTP services from `@mantl/nest-core` mock utilities
- Jest spies with `jest.spyOn()` + `mockImplementation()` / `mockResolvedValue()`
- `jest.resetAllMocks()` in `beforeEach`
- Test entity data from `@mantl/mantl-test-data` `entityMocks`

### Reporting

When completing a task, report:
- **Tests written:** what was covered and why
- **Tests skipped:** what additional tests could exist but were judged unnecessary, and why

## When You Need More Detail

If patterns unclear after reading example code:
1. Check [architecture.md](architecture.md) for core NestJS patterns
2. Check [bff-microservice-communication.md](bff-microservice-communication.md) for service communication
3. Look at 2-3 similar existing modules in the same service
