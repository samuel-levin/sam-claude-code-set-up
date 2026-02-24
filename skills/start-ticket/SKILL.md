# Start Ticket

Kick off work on a Jira ticket with full context loaded.

## When to use

- Starting work on any Jira ticket
- User says "start ticket", "pick up ticket", "work on [TICKET-123]"

## Instructions

### Step 1: Load the ticket

Use the Atlassian MCP tools to fetch the provided Jira ticket. Read the full description, acceptance criteria, comments, and attachments.

### Step 2: Gather epic context

Check if the ticket belongs to an epic. If so, fetch the other tickets in the epic to understand the broader scope and any dependencies or related work.

### Step 3: Load the x-darwin guide

Invoke `/x-darwin-guide`. Based on the ticket's requirements, the guide will load the relevant knowledge files for the work area.

### Step 4: Plan the work

With full ticket context and guide knowledge loaded, plan the implementation approach. Present the plan to the user before starting any code changes.
