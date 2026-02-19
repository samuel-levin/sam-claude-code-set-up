# X-Darwin Monorepo Guide

Use this skill when working on tickets or features in the x-darwin monorepo.

## Purpose

This skill encodes personal knowledge about the x-darwin repo's structure, idiosyncrasies, and common patterns. It acts as a routing guide to help navigate the codebase effectively.

**Goal:** Reach a state where ticket implementation can be fully automated. Every piece of knowledge added here reduces the need for human intervention. When you encounter something that required user correction or caused a wrong approach, it belongs in this guide.

## When to use

- Starting work on a Jira ticket
- Need context about x-darwin repo architecture
- Encountering x-darwin-specific gotchas
- Need to route to specialized knowledge areas

## Instructions

1. **Identify and load relevant documentation**

   Based on the ticket/work, determine which docs to read:
   - **Always read:** [architecture.md](architecture.md) - Core patterns (POST-only APIs, NestJS structure, monorepo layout)
   - **Always read:** [idiosyncrasies.md](idiosyncrasies.md) - Monorepo gotchas and workarounds
   - Creating new service/module/entity? → READ [creating-new-modules.md](creating-new-modules.md)
   - Console-API (BFF/GraphQL)? → READ [console-api-patterns.md](console-api-patterns.md)
   - Console-Web (Frontend)? → READ [console-web-patterns.md](console-web-patterns.md)
   - Client config changes? → READ [client-config.md](client-config.md)
   - Client config versioning? → READ [client-config-versioning.md](client-config-versioning.md) and FOLLOW the workflow
   - File exports (CSV/PDF)? → READ [file-export-patterns.md](file-export-patterns.md)
   - Jira ticket work? → READ [jira-conventions.md](jira-conventions.md)
   - BFF calling microservices? → READ [bff-microservice-communication.md](bff-microservice-communication.md)
   - Application service validation/requirements? → READ [application-service-patterns.md](application-service-patterns.md)

   When unsure if a file is relevant, read it — better to over-include than miss something.

2. **Work with the patterns**
   - Follow established patterns from the guide
   - If deviating from guide patterns, explain why
   - If the guide is missing information needed for the current task, tell the user what's missing and suggest adding it to the appropriate file

3. **Update guide with new learnings**

   When user provides missing information:
   - Ask: "Should I add [this info] to [appropriate-file.md]?"
   - Add it clearly and concisely following the style guidelines

4. **Route to specialized knowledge when needed**
   - Client config versioning workflow → Use [client-config-versioning.md](client-config-versioning.md) step-by-step
   - Browser testing → Invoke `/browser-testing` skill
   - Application service validation/requirements → Use [application-service-patterns.md](application-service-patterns.md)

## Style Guidelines

**Conciseness over verbosity:**
- Do NOT restate patterns that are already established in the codebase
- Only include code snippets if:
  - They represent something you had to research to discover
  - They show a departure from the usual system/patterns
  - They demonstrate a non-obvious implementation detail
- Assume engineers are familiar with the codebase patterns
- Focus on what's unique, unusual, or needs specific attention

## Notes

This is a living skill — build it out iteratively as you work through tickets.
