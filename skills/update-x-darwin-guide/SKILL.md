# Update X-Darwin Guide

Invoke after completing work to propose updates to the shared x-darwin knowledge guide.

## When to use

- After completing a ticket or significant chunk of work
- When you've discovered patterns or gotchas not in the guide
- When the user says "update the guide" or similar

## Instructions

### Step 1: Identify Candidates

Review the work done in this session. Identify knowledge that:
- Was missing from the guide and would have helped
- Required user correction or caused a wrong approach
- Represents a reusable pattern or gotcha (not a one-off)

For each candidate, present:
- **What**: Concise description of the knowledge
- **Where**: Which guide file it belongs in (e.g., `architecture.md`), or `NEW: filename.md` if no existing file fits
- **Why**: Why it would have helped during this session

If proposing a new file, also include:
- **File scope**: What topic area the new file covers
- **Routing trigger**: When should this file be loaded (the condition for the SKILL.md index)

Present candidates as a numbered list and **wait for user input**. The user will approve, reject, or modify each item.

### Step 2: Apply Approved Changes

For each approved candidate:
1. Read the target knowledge file's current content
2. Merge the new knowledge in cleanly — don't just append
3. Follow the style guidelines (below)
4. If overlapping with existing content, keep the better version

**If a candidate creates a new file:**
1. Create it at `~/.claude/skills/x-darwin-guide/knowledge/[filename].md`
2. Add a routing entry to `~/.claude/skills/x-darwin-guide/SKILL.md` under the doc list
3. Add the file to the Guide Structure Reference in `~/x-darwin/.claude/CLAUDE.md`
4. Add the file to `~/org-x-darwin-guide/index.md`

### Step 3: Summary

Report what was added, modified, or skipped.

Remind the user: "Changes are ready in the org guide repo. To share with the team, commit and push from `~/org-x-darwin-guide` to your engineer branch."

## Style Guidelines

- Concise over verbose
- Do NOT restate patterns already established in the codebase
- Only include code snippets if they represent something non-obvious or a departure from patterns
- Assume engineers are familiar with the codebase patterns
- Focus on what's unique, unusual, or needs specific attention

## Notes

Knowledge files live in `~/org-x-darwin-guide/knowledge/` (symlinked from the skill directory). Edits here are edits to the org repo. When pushed to an `engineers/*` branch, a GitHub Action runs the org-wide voting panel to decide what gets merged to main.
