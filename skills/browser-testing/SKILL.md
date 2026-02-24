---
name: browser-testing
description: Interactive browser-based testing of MANTL console features using Playwright MCP tools. Use after building a feature to validate it works end-to-end in a running dev environment.
---

# Browser Testing Skill

## Overview

Validate MANTL console features interactively using Playwright MCP tools against a running local dev environment. This is NOT about writing standalone test files — it's about Claude driving a browser session to verify features work.

## Prerequisites

- Dev environment running (`pnpm dev:conf` or equivalent)
- Playwright MCP tools available (`browser_navigate`, `browser_snapshot`, `browser_click`, etc.)
- Access to psql for database queries

## Workflow

1. **Understand what to test** — identify the feature, expected UI location, and data requirements
2. **Set up test data** — use psql to verify/create necessary data (clients, accounts, config)
3. **Navigate to the feature** — log in, select tenant, navigate to the right page
4. **Interact and verify** — fill forms, click buttons, check results
5. **Debug failures** — if something doesn't work, investigate (check console errors, query DB, inspect GraphQL responses)
6. **Report results** — summarize what worked, what didn't, and any bugs found

## Key Principles

- **Use `browser_snapshot` over `browser_take_screenshot`** — snapshots return an accessibility tree with ref IDs you can interact with. Screenshots are just images.
- **Wait for page loads** — use `browser_wait_for` after navigation. Pages can be slow locally.
- **One action at a time** — click, then snapshot to see the result. Don't chain actions blindly.
- **Debug then report** — if something fails, investigate autonomously (check console, query DB, inspect network). Attempt one fix. If still broken, report findings.

## Knowledge Files

- `knowledge/database-patterns.md` — How to query and modify MANTL data via psql
- `knowledge/navigating-the-ui.md` — How to navigate the MANTL console with Playwright MCP tools

## Environment

- **Console URL:** `http://console.mantl.localhost`
- **Default credentials:** `mantl+admin@mantl.com` / `M@nt1`
- **Database:** PostgreSQL accessible via `psql` (default local connection)
