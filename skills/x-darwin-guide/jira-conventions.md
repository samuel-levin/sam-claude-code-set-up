# Jira Conventions for X-Darwin

## Ticket Key Format

Jira tickets follow the pattern: `{TEAM}-{NUMBER}`

- **Team identifier**: Series of uppercase letters (e.g., `ENH`, `LOAN`, `PROD`)
- **Separator**: Dash (`-`)
- **Ticket number**: Series of digits (e.g., `3295`, `1079`)

**Examples:**
- `ENH-3295`
- `LOAN-1079`
- `PROD-20379`

**Parsing from branch names:**
Branch names often include the ticket key as a prefix:
- `ENH-3295/fix-pdf-regen` → ticket key is `ENH-3295`
- `PROD-20379/split-up-aor-jobs` → ticket key is `PROD-20379`

## Custom Fields

### Testing Considerations (Custom Field)

**CRITICAL**: Our Jira tickets have a **Testing Considerations** custom field.

**Rule**: ALL testing-related notes must go in this custom field, NOT in the ticket description or implementation panels.

**What goes in Testing Considerations:**
- Test plans and test scenarios
- Edge cases to verify
- QA guidance
- Regression test notes
- Testing gotchas or special considerations

**When using jira-ticket-refine:**
- Do NOT include testing notes in the "Cursor Implementation Instructions" panel
- Research and identify testing considerations during codebase exploration
- Update the Testing Considerations custom field separately using Jira MCP
- Use `jira_get` first to find the custom field ID (it will be `customfield_XXXXX`)
- Update with `jira_put` or `jira_patch`: `body: {"fields": {"customfield_XXXXX": "..."}}`

**Example workflow:**
1. Research codebase for implementation notes
2. Identify testing considerations separately
3. Update ticket description with Cursor Implementation Instructions panel (no testing notes)
4. Update Testing Considerations custom field with all testing-related content

## Ticket Structure

(Add more as discovered)

## Story Pointing Calibration

(Add team-specific calibration if different from org defaults)

## Workflow Conventions

(Add branch naming, status transitions, labels, etc.)
