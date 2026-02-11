# Console-Web (Frontend) Patterns

## Directory Structure

```
src/console-web/
├── src/
│   ├── pages/              # Next.js pages
│   │   └── console/
│   │       ├── dbm-v3/    # DBM routing
│   │       ├── customers/
│   │       └── ...
│   ├── web/                # Application logic
│   │   ├── dbm-v3/        # DBM feature modules
│   │   ├── customers/
│   │   ├── shared/        # Shared utilities
│   │   │   ├── graphql/   # useRelayMutation, etc.
│   │   │   ├── modal/
│   │   │   └── toast/
│   │   └── ...
│   ├── UI/                 # Component library (60+ components)
│   └── ...
├── lib/__generated__/      # Generated Relay types (1000+ files)
└── relay.config.js         # Relay configuration
```

## DBM (Digital Branch Manager)

Configuration management system for financial institutions.

**Location:** `src/console-web/src/web/dbm-v3/`

**Modules:**
- `branding/` - Logo, colors, footer, border shapes
- `products/` - Product configuration, rates, funding
- `regions/` - Geographic configuration
- `services/` - Available services
- `compliance/` - Attestations and agreements
- `documents/` - Document types
- `client-setup/` - Client details, field options
- `integrations/` - External systems (DMS, card printers)
- `fields/` - Custom field configuration
- `interest-rates/` - Rate tier management
- `notifications/` - Notification config

## GraphQL Client: Relay

Uses **Meta Relay** for GraphQL state management.

### Mutation Hook Pattern (Preferred)

```typescript
// 1. Define mutation
const mutation = graphql`
  mutation useUpdateRegionMutation($input: UpdateRegionInput!) {
    UpdateRegion(input: $input) {
      region { name code }
    }
  }
`

// 2. Create hook
const useUpdateRegionMutation = () => {
  return useRelayMutation<useUpdateRegionMutationType>({ mutation })
}

// 3. Use in component
const { commit, isLoading } = useUpdateRegionMutation()
await commit({ variables: { input: { ... } } })
```

**Location:** `src/web/helpers/useRelayMutation.ts`

**Features:**
- Promise-based API (wraps Relay's callback API)
- Built-in error handling with toast notifications
- Loading state management
- Handles error codes: `UNAUTHORIZED`, `UNAVAILABLE`, `VERSIONING_IN_PROGRESS`

### Query Pattern

```typescript
// useLazyLoadQuery for component-mount fetching
const data = useLazyLoadQuery(query, variables)

// useFragment for nested data
const fragment = useFragment(fragmentSpec, fragmentRef)

// useRefetchableFragment for refetchable data
const [data, refetch] = useRefetchableFragment(fragmentSpec, fragmentRef)
```

### Build System

**Relay Compiler:**
- Reads GraphQL schema from console-api
- Generates TypeScript types from queries/mutations
- Output: `lib/__generated__/` (1000+ files)

**Command:** `relay-compiler`

### Error Handling

Built into `useRelayMutation`:
- Network errors → "Error processing request" toast
- Forbidden → "Access Restricted" toast
- Versioning in progress → "Configuration versioning in progress" toast

## Module Organization Pattern

Each feature follows:
```
feature/
├── views/          # Page components
├── components/     # UI components
├── sheets/         # Modal/dialog forms
├── graphql/        # Query/mutation hooks
├── helpers/        # Utilities
└── types/          # TypeScript types
```

## Shared Patterns

**Toast System** (`src/web/shared/toast/`):
```typescript
const { showAlertToast, showConfirmationToast } = useToast()
showAlertToast('Error message')
```

**Modal System** (`src/web/shared/modal/`):
- Context-based modal management

**Forms:**
- `react-hook-form` for form state
- `react-select` for dropdowns
- `react-imask` for input masking

**Authorization:**
- `useDBMAuth` hook for DBM permissions
- `withAuthNav` HOC for page-level auth

## Key Dependencies

- `next` - React framework
- `react-relay` - GraphQL client
- `react-hook-form` - Forms
- `styled-components` - CSS-in-JS
- `@pandacss/dev` - Styling system
- `@radix-ui/*` - Accessible primitives
- `react-table` - Table management
