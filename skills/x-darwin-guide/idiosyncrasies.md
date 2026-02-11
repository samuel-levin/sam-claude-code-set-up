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

## Known Issues

(Document gotchas as you discover them)

## Common Mistakes

-

## Quirks to Remember

-

## Workarounds

-
