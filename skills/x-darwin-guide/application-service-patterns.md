# Application Service Patterns

## Double-Layer: Requirements + Required Actions

The application service uses a two-layer system for tracking what an application needs:

1. **Requirements** (`Requirement[]`) - Detailed, typed objects describing what's needed. Each has a `type`, `entity`, and `status` (`complete` | `incomplete`). Used by the frontend to render UI.
2. **Required Actions** (`IRequiredAction[]`) - Status-level indicators that drive reconciliation. Each has a `type`, `entityId`, `entityType`, `data`, and optional `referenceId`.

Both layers are generated together by `get<X>RequirementsAndRequiredActions()` methods in eval services, then spread/concatenated into the validation flow's `newRequirements` and `newRequiredActions` arrays.

Required actions go through `reconcileRequiredActions()` which uses locked review/execution statuses from the `configuration` Record in `helpers/requiredActions.ts`.

## Account-Scoped Required Actions

When a required action is scoped to a specific account (not the application as a whole):

- `entityType`: `common.EntityType.ACCOUNT`
- `referenceId`: the account's `referenceId` (this is the primary account identifier)
- `data`: descriptive content only (field names, service IDs) - NOT used for account references

This matches the pattern used by account-level EDD required actions. The `referenceId` field is the canonical way to associate a required action with a specific account.

## Adding a New RequiredActionType

Three files must be updated:

1. `packages/transport-http-typings/src/application-service/application.ts`:
   - Add to `requiredActionTypes` const array
   - Add to deprecated `RequiredActionType` const object
2. `src/application-service/src/modules/application/helpers/requiredActions.ts`:
   - Add reconciliation config entry with `lockedReviewStatuses` and `lockedExecutionStatuses`

## Validation Flow Differences: createAccount vs CDASO

The two main validation services assemble requirements/required actions differently:

**`application-validate-create-account.service.ts`:**
- Flat spread arrays: `newRequirements: [...a, ...b, ...c]` and `newRequiredActions: [...x, ...y, ...z]`
- Eval service results are spread directly into these arrays

**`application-validate-consumer-deposit-add-secondary-owner.service.ts` (CDASO):**
- Uses `peopleData` object with `.requiredActions` and `.requirements` sub-arrays
- Top-level assembly uses `.concat()` chains for required actions
- Requirements use spread syntax at the final assembly point

When wiring a new eval service into both flows, adapt to each flow's assembly pattern rather than forcing uniformity.

## CDASO Multi-Joint Owner: Beware Per-Person Duplication

In the CDASO validate service, `getMultiJointOwnersData` calls `getPersonDataWithPersonId` in a loop for each joint owner. Any data fetching or required action generation inside `getPersonDataWithPersonId` runs N times.

When adding cross-cutting concerns (e.g., IOI detection, beneficiary logic), hoist them to `getMultiJointOwnersData` or the top-level method — not inside `getPersonDataWithPersonId`. The review service already follows this pattern (single fetch at top level).

## Scope-Filtering Required Actions: Attestations AND Signatures

When filtering required actions to a specific scope (e.g., `hasBeneficiary`), both attestations and signatures must be post-filtered via `qualifyingScopes`:

- Attestations: `config.attestationTypes[id].qualifyingScopes`
- Signatures: `config.agreements[id].qualifyingScopes`

Both follow the same pattern. It's easy to filter one and forget the other.

## Eval Service Structure

All eval services follow:

- `@Injectable({ scope: Scope.REQUEST })` - request-scoped
- Inject `@Inject(SCOPED_LOGGER) private readonly logger: Logger`
- Logger child with `{ class: this.serviceName }`
- Method logging: `this.logger.info('#methodName:executing')`
- Return typed `{ requirements, requiredActions }` tuple
- Register in `application.module.ts` providers and inject into validation services
