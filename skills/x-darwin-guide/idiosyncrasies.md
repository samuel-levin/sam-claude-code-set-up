# X-Darwin Idiosyncrasies & Gotchas

## Working in the Monorepo

### Never `cd` into specific packages

**DON'T:**
```bash
cd packages/client-config && pnpm run build
```

**DO:**
```bash
pnpm turbo --filter=@mantl/client-config build
# or from root:
pnpm --filter @mantl/client-config build
```

**Why:** Services are highly interdependent. Running commands from within a package directory can cause:
- Incorrect dependency resolution
- Missing shared tooling configuration
- Build failures due to incorrect context

### Dependency build failures are blockers

If a dependent package fails to build (e.g., `@mantl/domain`), this is a blocker:
- **First:** Ensure you've run `pnpm install` from root
- **Second:** Ensure you've pulled latest from your base branch (usually `integration`)
- **If still failing:** The build issue must be fixed before proceeding - it's either:
  - Something we need to fix in our changes
  - A pre-existing issue that needs investigation

Don't try to work around dependency build failures by building packages in isolation.

### Git worktrees need vault secrets for tests

New git worktrees don't have `secrets.json` files, which contain Redis config and other service credentials. Without them, any test that imports `@mantl/nest-core` will fail with `Host and port must be provided` from `RedisClientModule.register()`.

Fix: run `vault-pull` for the service you're testing:
```bash
pnpm --filter @mantl/application-service vault-pull
```

Each service has its own vault-pull config. Check the service's `package.json` for the exact script.

### Running tests

Use `pnpm --filter` with the test filename (no `--testPathPattern` or `--` needed):
```bash
pnpm --filter @mantl/application-service test some-test.unit.spec.ts
pnpm --filter @mantl/domain test getApplicationScopes.spec.ts
```

### Domain package tests need extra memory

`@mantl/domain` uses `ts-jest` and the package is large enough to exceed the default Node heap limit, causing a SIGABRT crash. This is worse in fresh worktrees with no Jest cache. Prefix with extra memory:
```bash
NODE_OPTIONS='--max-old-space-size=5120' pnpm --filter @mantl/domain test someTest.spec.ts
```

The domain `test:ci` script already sets this, but the local `test` script does not.

### `ConsumerDepositCreateAccount` scope is deprecated

Use `createAccount` instead of `consumerDepositCreateAccount` in scopes. The `ConsumerDeposit`-prefixed variants are deprecated throughout the system. When writing tests or referencing scopes, always use the unprefixed form (e.g., `createAccount`, not `consumerDepositCreateAccount`).

### Local type-check requires building dependencies first

`pnpm --filter @mantl/{service} type-check` runs `tsc` in isolation. If sibling packages aren't built, you'll get hundreds of false `TS2307: Cannot find module` errors. CI handles this automatically, but locally you must build first:

```bash
pnpm turbo --filter=@mantl/{service} build   # builds service + all deps
pnpm --filter @mantl/{service} type-check    # now works correctly
```
