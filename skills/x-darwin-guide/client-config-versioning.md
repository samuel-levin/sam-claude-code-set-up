# Client Configuration Versioning Workflow

## ⚠️ CRITICAL: Commit Strategy

**Versioning changes MUST be in a separate commit.**

The following changes should be isolated in their own commit:
- Creating the versioning seed
- Creating the lock file (`lock:validation-schema`)
- Updating `CONFIG_SCHEMA_VERSION` in `packages/constants/src/clientConfiguration.ts`

**Why:** If someone gets ahead of us in the versioning queue, we need to:
1. Update the version constant to the next available number
2. Regenerate the lock file

If these changes are in a separate commit, we can simply drop that commit and regenerate. If mixed with other changes, we have to manually edit the commit, which is messy.

**Recommended Git Flow:**
```bash
# Commit 1: Schema and code changes
git commit -m "Add new field to client config schema"

# Commit 2: Versioning artifacts (separate!)
git commit -m "Client config version [VERSION]: lock file and seed"
```

---

## Versioning Workflow

### In the `client-config` Package

**1. Make changes to the current schema**

Location: `packages/client-config/src/validation/current-schema`

**2. Build client-config (and dependencies)**

```bash
pnpm turbo --filter=@mantl/client-config build
```

**3. Test changes against presets and builders**

```bash
pnpm --filter @mantl/client-config test
```

**4. Update presets or builders as needed**

Fix any test failures from step 3.

**5. Increment `CONFIG_SCHEMA_VERSION`**

Location: `packages/constants/src/clientConfiguration.ts`

**Note:** This constant has moved from `@mantl/client-config` to `@mantl/constants`.

**6. Build the constants package**

```bash
pnpm --filter @mantl/constants build
```

**7. Generate locked validation schema**

```bash
pnpm --filter @mantl/client-config lock:validation-schema
```

**8. Commit versioning files (separate commit)**

**CRITICAL:** These versioning artifacts must be in their own commit (see commit strategy at top).

```bash
git add packages/constants/src/clientConfiguration.ts packages/client-config/src/validation/locked-schemas/validationSchema.[VERSION].locked.json
git commit -m "Increment schema version [VERSION]"
```

This isolated commit makes it easy to regenerate if someone gets ahead in the versioning queue.

---

### In the `client-service` Package

**9. Build/rebuild client-service**

```bash
pnpm turbo --filter=@mantl/client-service build
```

**10. Create versioning seed (ONLY if requested by user)**

**Note:** Versioning seeds are only needed when existing client config data requires transformation. Most schema additions (new fields, new types) do NOT require seeds. Only create a seed if:
- The user explicitly requests it
- You're removing or renaming required fields
- You're changing validation rules that would break existing data

If a seed is needed:

```bash
pnpm --filter @mantl/client-service generate:versioning-seed
```

**11. Export the seed from index file (if seed was created)**

Location: `src/client-service/db/seeds-versioning/index.ts`

```typescript
// Example
import { seed as seedVersion156 } from './seed.version.156'

export const versioningSeeds = {
  156: seedVersion156,
}
```

**12. Test against integration data**

**❗️NEW VERSIONING REQUIREMENT**

```bash
# Ensure you're connected to SDM
pnpm dev:run --filter=@mantl/client-service

# Test against environment(s)
pnpm --filter @mantl/client-service test:configuration-versioning --env=all
# Options: --env=all | --env=int | --env=uat | --env=demo | --env=prod
```

**To test against prod:** Request access via Slack `/request-access to PROD_RO`

**13. Create PR and notify #configuration**

Post in [#configuration](https://mantlteam.slack.com/archives/CQ7QP7U6Q) Slack channel to grab a version number 🎉

---

## Checklist

Before creating your PR:

- [ ] Schema changes made in `src/validation/current-schema`
- [ ] `client-config` tests pass
- [ ] `CONFIG_SCHEMA_VERSION` incremented in `@mantl/constants`
- [ ] Lock file generated (`lock:validation-schema`)
- [ ] **Versioning files committed in separate commit**
- [ ] Versioning seed created (if needed - only when requested)
- [ ] Seed exported in `seeds-versioning/index.ts` (if created)
- [ ] Tested against integration data
- [ ] PR created and posted in #configuration

---

## Common Issues

### Someone Got Ahead in the Queue

**Problem:** Another PR was merged with a version number you were planning to use.

**Solution:**
1. Check out your branch
2. Drop the versioning commit: `git reset --soft HEAD~1` (or rebase interactive)
3. Update `CONFIG_SCHEMA_VERSION` to next available number
4. Regenerate lock file: `pnpm --filter @mantl/client-config lock:validation-schema`
5. Regenerate seed: `pnpm --filter @mantl/client-service generate:versioning-seed`
6. Update seed export in `seeds-versioning/index.ts` with new version number
7. Create new commit with versioning artifacts
8. Force push and update PR

This is why versioning changes must be in a separate commit!

### Test Failures

If `test:configuration-versioning` fails:
- Check the error output for which client configs are invalid
- Update your seed to handle edge cases
- Re-run tests

---

## Key Files

| File | Purpose |
|------|---------|
| `packages/client-config/src/validation/current-schema/` | Schema definitions |
| `packages/constants/src/clientConfiguration.ts` | `CONFIG_SCHEMA_VERSION` constant |
| `packages/client-config/src/validation/locked-schemas/` | Generated lock files |
| `src/client-service/db/seeds-versioning/` | Versioning seeds |
| `src/client-service/db/seeds-versioning/index.ts` | Seed export registry |
