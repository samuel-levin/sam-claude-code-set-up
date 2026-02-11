# X-Darwin Monorepo Guide

Use this skill when working on tickets or features in the x-darwin monorepo.

## Purpose

This skill encodes personal knowledge about the x-darwin repo's structure, idiosyncrasies, and common patterns. It acts as a routing guide to help navigate the codebase effectively.

## When to use

- Starting work on a Jira ticket
- Need context about x-darwin repo architecture
- Encountering x-darwin-specific gotchas
- Need to route to specialized knowledge areas

## Instructions

1. **Identify and load relevant documentation (MANDATORY)**

   Based on the ticket/work, determine which docs to read:
   - **Always read:** [architecture.md](architecture.md) - Core patterns (POST-only APIs, NestJS structure, monorepo layout)
   - Creating new service/module/entity? → READ [creating-new-modules.md](creating-new-modules.md) - Step-by-step checklist
   - Console-API (BFF/GraphQL)? → READ [console-api-patterns.md](console-api-patterns.md)
   - Console-Web (Frontend)? → READ [console-web-patterns.md](console-web-patterns.md)
   - Client config changes? → READ [client-config.md](client-config.md)
   - Client config versioning? → READ [client-config-versioning.md](client-config-versioning.md) and FOLLOW the workflow
   - File exports (CSV/PDF)? → READ [file-export-patterns.md](file-export-patterns.md)
   - Jira ticket work? → READ [jira-conventions.md](jira-conventions.md)
   - BFF calling microservices? → READ [bff-microservice-communication.md](bff-microservice-communication.md)

2. **Read and report (MANDATORY)**

   Provide a structured report to the user:

   ```
   📚 Guide Check:

   Read from guide:
   - [file1.md]: [key patterns/info found]
   - [file2.md]: [key patterns/info found]

   ❓ Missing from guide:
   - [Specific topic 1]: [What I need to know]
   - [Specific topic 2]: [What I need to know]

   Questions:
   - [Specific question about how to proceed]
   ```

   **Do not proceed until:**
   - User confirms existing info is correct
   - User provides missing information
   - OR user says "proceed with what you have"

3. **Work with the patterns**
   - Follow established patterns from the guide
   - Cite relevant patterns when explaining your approach
   - Don't reinvent approaches that are already documented
   - If deviating from guide patterns, explain why

4. **Update guide with new learnings**

   When user provides missing information:
   - Ask: "Should I add [this info] to [appropriate-file.md]?"
   - Add it clearly and concisely following the style guidelines
   - Note what was learned for future tickets

5. **Before marking changes complete**
   - Invoke `/browser-testing` to validate changes in browser
   - Follow testing guidance for the type of change made
   - Report validation results before considering work done

6. **Route to specialized knowledge when needed**
   - Client config versioning workflow → Use [client-config-versioning.md](client-config-versioning.md) step-by-step
   - Browser testing → Invoke `/browser-testing` skill
   - PDF generation issues → (skill to be created)
   - Account service → (skill to be created)
   - Loan processing → (skill to be created)

## Before Proposing Changes - Verification Checkpoint

Ask yourself:
- [ ] Did I invoke /x-darwin-guide at the start?
- [ ] Did I read the relevant pattern docs for this work area?
- [ ] Did I provide the structured report showing what I read and what's missing?
- [ ] If information was missing, did I wait for user input?
- [ ] Am I following patterns documented in the guide?
- [ ] If I'm uncertain, did I ask rather than guess?

**If any answer is "no", go back and complete that step.**

## Style Guidelines

**Conciseness over verbosity:**
- Err on the side of being concise in all documentation and implementation notes
- Do NOT restate patterns that are already established in the codebase
- Only include code snippets if:
  - They represent something you had to research to discover
  - They show a departure from the usual system/patterns
  - They demonstrate a non-obvious implementation detail
- Assume engineers are familiar with the codebase patterns
- Focus on what's unique, unusual, or needs specific attention

## Notes

This is a living skill - build it out iteratively as you work through tickets.
