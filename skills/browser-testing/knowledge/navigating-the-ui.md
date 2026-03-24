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

**After login, you land on the dashboard** — click TENANTS in the left nav, then select a tenant before accessing any features.

## Tenant Selection

1. After login, click "TENANTS" in the left sidebar navigation
2. Wait for the tenant list to load (this can be **very slow** — the list is large and loads lazily)
3. The default tenant is "Neue Bank" — it may not be visible without scrolling. The search box does NOT filter the list in real time.
4. Find the "Neue Bank" row and click its Launch button (icon in the last column)
5. Wait for the tenant's dashboard to load — you'll see "NEUE BUSINESS" in the nav and side nav items like CUSTOMERS, APPLICATIONS, etc.

## Navigating to an Account

### Via UI (preferred)
1. Click "CUSTOMERS" in the left sidebar
2. Click the "Accounts" tab
3. Find the account in the table and click it

### Via Direct URL (only when UI navigation is impractical)
1. Construct the Relay ID:
   ```bash
   echo -n "cao_account:<account-uuid>" | base64
   ```
2. Navigate to: `http://console.mantl.localhost/console/customers/accounts/<relay-id>`
3. **Prefer UI navigation over direct URLs** — use clicks to get where you need to go. Only use Relay ID URLs when there's no practical UI path (e.g., navigating to a specific account from scratch with only a UUID).

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

## Creating an Account (Open New Account Flow)

1. From the Customers queue, click "Open New Account"
2. Select entity type (Personal, Business, Trust, etc.)
3. Select product (e.g. "Free Checkings" → "Single Party Account")
4. Search for primary owner by SSN:
   - **Default person SSN:** `234-23-4234` (enter as `234234234`)
   - **Default org EIN:** `432-43-2432`
   - These are stable across sessions but need recreation after a DB reset
   - If no match found, "New Applicant" is auto-selected — click Continue
5. Fill Person Profile (First Name, Last Name, DOB, Email, Phone, Address)
6. **Address is an autocomplete** — type in Address Line 1, then click any suggested value. City/State/Zip will auto-populate.
7. Save the person profile
8. Submit for Review → check the bypass checkbox → Submit Decision
9. Auto-booking kicks in asynchronously — **may need a page refresh to see the final "Successfully Booked" status**

## Timeouts and Waiting

Local dev is frequently slow. Use generous waits and expect lag:
- After navigation: `browser_wait_for` with expected page text, or `time: 3`
- After form submission: wait for success toast or confirmation text
- After tenant launch: wait for dashboard elements to appear
- **After booking:** The booking processes asynchronously via Kafka. The UI may show "Booking..." for 10-30+ seconds. If it seems stuck, try refreshing the page — the booking may have completed but the UI didn't update.
- **Tenant list:** Loading is slow with many tenants. Be patient.

## Service Restarts and the Browser

Restarting backend services (console-api, etc.) while the browser is open will cause WebSocket disconnects and SSR errors like `Cannot read properties of undefined (reading 'applicationInterface')`. After restarting:
- Wait at least 20-30 seconds for the service to fully initialize
- Reload the page — a single reload may fail during SSR; try again if needed
- If an error overlay appears in Next.js dev mode, reload the page to clear it

## CDASO Beneficiary with Signatures Flow

This is the flow for adding/editing beneficiaries on an existing account via a CDASO (Consumer Deposit Add Secondary Owner) application:

1. Navigate to the account page
2. Click **"Add Beneficiary with Signatures"** button in the "Manage Beneficiaries" card
3. Fill the beneficiary form: First Name, Last Name, Tax ID, DOB, Allocation Percentage (required fields marked with *)
4. Click **"Create Application"** — success toast: "Application created successfully"
5. Auto-navigates to the CDASO application checklist
6. **Edit a beneficiary:** Click MANAGE on the Beneficiaries section → click Edit on the beneficiary card → modify fields → click Save
7. **Attestations:** Click "Signatures & Attestations" in Account Setup → click Attestations to view them → go back → close sheet
8. **Submit:** Click "Submit for Review" → check bypass checkbox → click "Submit Decision"
9. Application auto-approves and begins booking asynchronously
10. Refresh page after 15-30 seconds to see "Successfully Booked" status

## Tips

- Always `browser_snapshot` after any action to see what happened
- Ref IDs change between snapshots — always get fresh refs before interacting
- If a button/link isn't in the snapshot, the page may not be fully loaded or the element may require scrolling
- Use `browser_evaluate` to run JS in the page context for debugging (e.g., check Relay store, window variables)
- **Prefer UI navigation over direct URLs** — click through the UI to reach pages. Only use Relay ID URLs when UI navigation is impractical.
- **Prefer pure browser testing** — avoid relying on e2e test helpers (`@mantl/mantl-test-data`) for data setup. Create data through the UI or use MCP tools (read_client_config, read_application) for verification.
- **Do not run e2e tests** — leave e2e test execution to the user. This role is automated browser-based QA testing using Playwright MCP tools, not running TestCafe/test suites.
- **Lag awareness:** The local dev environment has inherent lag. If an action appears to fail or get stuck, wait longer and/or refresh before concluding it failed. Check the database via MCP tools to confirm actual state.
- **Clearing text fields:** To replace text in a pre-filled input, click the field, press `Meta+a` to select all, then type the new value (which will use `.fill()` and replace).
- **Toasts confirm actions:** After mutations (create, edit, submit), look for `status` role elements in the "Notifications" region — these are success/error toasts.
