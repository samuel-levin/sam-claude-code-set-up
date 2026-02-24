# Navigating the UI

How to navigate the MANTL console using Playwright MCP tools.

## Core Playwright MCP Tools

| Tool | When to use |
|------|-------------|
| `browser_navigate` | Go to a URL |
| `browser_snapshot` | Get accessibility tree with ref IDs (preferred over screenshots) |
| `browser_click` | Click an element by ref ID |
| `browser_fill_form` | Fill form fields by ref ID |
| `browser_type` | Type into a focused element |
| `browser_wait_for` | Wait for text to appear/disappear or a timeout |
| `browser_console_messages` | Check for JS errors |
| `browser_take_screenshot` | Visual capture (use snapshot for interaction) |

## Login Flow

1. Navigate to `http://console.mantl.localhost`
2. This redirects to the login page at `/auth/login`
3. Fill email and password fields:
   ```
   browser_fill_form: [
     { name: "email", type: "textbox", ref: <email-ref>, value: "mantl+admin@mantl.com" },
     { name: "password", type: "textbox", ref: <password-ref>, value: "M@nt1" }
   ]
   ```
4. Click the Sign In button
5. Wait for the dashboard to load

**After login, you land on the Tenants page** — you must select a tenant before accessing any features.

## Tenant Selection

1. After login, take a `browser_snapshot` to see the tenant list
2. Look for the tenant name (e.g. "Neue Bank", "NeueBusiness")
3. Click the "Add" button (top-left area) or find the tenant row
4. Click "Launch" on the desired tenant
5. Wait for the tenant's dashboard to load

## Navigating to an Account

### Via UI
1. Click "CUSTOMERS" in the left sidebar
2. Click the "Accounts" tab
3. Find the account in the table and click it

### Via Direct URL (faster)
1. Construct the Relay ID:
   ```bash
   echo -n "cao_account:<account-uuid>" | base64
   ```
2. Navigate to: `http://console.mantl.localhost/console/customers/accounts/<relay-id>`

## Reading Snapshot Output

`browser_snapshot` returns an accessibility tree. Key things to look for:

- **Refs** like `[ref=e42]` — use these with `browser_click`, `browser_fill_form`, etc.
- **Role labels** like `button "Submit"`, `textbox "Email"`, `link "Accounts"`
- **Structure** — headings, regions, and groups show page layout

Example snapshot excerpt:
```
- heading "Account Details" [level=2]
- button "Add Beneficiary" [ref=e108]
- textbox "First Name" [ref=e112]
```

## Common Patterns

### Fill and Submit a Form
1. `browser_snapshot` to find field refs
2. `browser_fill_form` with all fields
3. `browser_click` on the submit button
4. `browser_wait_for` for success indicator
5. `browser_snapshot` to verify result

### Check for UI Elements
1. `browser_snapshot` and search the output for expected text/components
2. If not found, check:
   - Is the page fully loaded? Use `browser_wait_for`
   - Are there console errors? Use `browser_console_messages`
   - Is the data correct? Query the DB

### Debug Missing UI Elements
1. `browser_console_messages` — check for JS errors or failed GraphQL requests
2. `browser_snapshot` — look at what IS rendered to understand the page state
3. Query the database — verify the backing data exists and is correct
4. Check GraphQL — use `browser_evaluate` to inspect Relay store or network responses

## Timeouts and Waiting

Local dev can be slow. Use generous waits:
- After navigation: `browser_wait_for` with expected page text, or `time: 3`
- After form submission: wait for success toast or confirmation text
- After tenant launch: wait for dashboard elements to appear

## Tips

- Always `browser_snapshot` after any action to see what happened
- Ref IDs change between snapshots — always get fresh refs before interacting
- If a button/link isn't in the snapshot, the page may not be fully loaded or the element may require scrolling
- Use `browser_evaluate` to run JS in the page context for debugging (e.g., check Relay store, window variables)
