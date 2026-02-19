# Update X-Darwin Guide

Invoke after completing work to review and update the x-darwin guide with new learnings.

## When to use

- After completing a ticket or significant chunk of work
- When you've discovered patterns or gotchas not in the guide
- When the user says "update the guide" or similar

## Vote History

Past voting decisions and user feedback are logged at:
`~/.claude/skills/x-darwin-guide/vote-history.jsonl`

This file is append-only. Each line is a JSON object representing one voting session.

## Instructions

### Step 1: Identify Candidates

Review the work done in this session. Identify knowledge that:
- Was missing from the guide and would have helped
- Required user correction or caused a wrong approach
- Represents a reusable pattern or gotcha (not a one-off)

For each candidate, prepare:
- **What**: Concise description of the knowledge
- **Where**: Which guide file it belongs in, or `NEW: filename.md` if no existing file is a good fit
- **Why**: Why it would have helped during this session

If proposing a new file, also include:
- **File scope**: What topic area the new file covers
- **Routing trigger**: When should this file be loaded (the condition for the SKILL.md index)

Format each candidate as a numbered item and present them to the user. The user may remove, modify, or add candidates before voting proceeds.

### Step 2: Voting Panel

Once candidates are confirmed:
1. Read the content of each target guide file so voters have full context
2. Read the vote history log at `~/.claude/skills/x-darwin-guide/vote-history.jsonl` (if it exists)

Then spawn **5 voter subagents in parallel** using the Task tool:
- `subagent_type: "Explore"`
- `model: "haiku"`

Each voter receives the same prompt containing:
1. Their personality (below)
2. All candidate items (what, where, why)
3. The current content of each target guide file
4. The guide's style guidelines (from x-darwin-guide/SKILL.md)
5. The vote history log (so they can reference past decisions and user feedback)

Instruct each voter: "You may use Read, Grep, and Glob to research the codebase and verify claims before voting. Review the vote history for context on past decisions — note any patterns in what was approved, rejected, or overridden by the user."

Each voter must respond in this exact format per candidate:

```
Candidate 1: [title]
Vote: YES or NO
Reasoning: [1-2 sentences]
```

#### Voter Personalities

**The Skeptic:**
You are the Skeptic. Your job: challenge necessity. For each candidate ask — Will this actually come up again, or was it a one-off? Is this specific enough to be actionable? Would a competent developer figure this out quickly from the code alone? Check the vote history: has similar info been proposed and rejected before? Vote YES only if you're convinced this saves real time on future work. Vote NO if it's a one-time discovery or something obvious from reading the code.

**The Archivist:**
You are the Archivist. Your job: preserve institutional knowledge. For each candidate ask — If the person who discovered this left, would the next person hit the same wall? Is this knowledge that lives in someone's head and gets lost? Was it genuinely hard to discover? Check the vote history: has the user overridden rejections for this type of knowledge before? Vote YES if this knowledge was earned through effort and could easily be lost. Vote NO only if it's trivially discoverable or already well-documented.

**The Historian:**
You are the Historian. Your job: spot patterns and recurring themes. For each candidate ask — Is this an instance of a broader pattern? Does it connect to or extend existing guide documentation? Does it fill a gap in the guide's coverage? Check the vote history: has similar knowledge come up in past sessions? If so, that strengthens the case for inclusion. Vote YES if this represents a recurring pattern or fills a meaningful gap. Vote NO if it's an isolated fact with no broader significance.

**The Devil's Advocate:**
You are the Devil's Advocate. Your job: argue the risks of inclusion. For each candidate ask — Could this become stale as the codebase evolves? Does it duplicate or contradict existing guide content? Would adding it create noise that dilutes more important information? Check the vote history: have past additions of this type held up well or become stale? Vote YES only if the benefits clearly outweigh the maintenance burden. Vote NO if there's meaningful risk of staleness, contradiction, or noise.

**The Router:**
You are the Router. Your job: evaluate navigational value. For each candidate ask — Does this help someone reach the right approach faster? Does it prevent wrong turns or dead ends? Is it placed in the right file? If a new file is proposed, is it justified or could this fit in an existing file? Check the vote history: does the placement align with how past additions were filed? Vote YES if this meaningfully reduces the time from "I have a task" to "I know the right approach." Vote NO if it doesn't help with decision-making or routing. If you vote YES but disagree with the proposed file placement, note your suggested alternative in your reasoning.

### Step 3: Tally and Apply

Collect all votes and present results:

```
## Vote Results

### Approved (3+/5)
- [Candidate]: [Y/N counts] — Adding to [file.md]
  Summary: [why it passed]

### Rejected (<3/5)
- [Candidate]: [Y/N counts] — Not adding
  Summary: [why it failed]
```

Wait for user confirmation. The user may:
- Approve all changes
- Override a rejection (force-add an item)
- Override an approval (skip an item)
- Modify an item before it's added

Apply approved changes following the style guidelines:
- Concise over verbose
- No code snippets unless non-obvious or departure from patterns
- Focus on what's unique, unusual, or needs specific attention

**If an approved candidate targets a new file:**
1. Create the file at `~/.claude/skills/x-darwin-guide/[filename].md`
2. Add a routing entry to `~/.claude/skills/x-darwin-guide/SKILL.md` under the "Knowledge Files" list with the filename, description, and when-to-load trigger
3. Add the file to the Guide Structure Reference in `~/x-darwin/.claude/CLAUDE.md`

If the Router voter suggested an alternative placement and you agree, use that instead and note the change in the results.

### Step 4: Log Results

After changes are applied, append a JSON entry to `~/.claude/skills/x-darwin-guide/vote-history.jsonl`:

```json
{
  "date": "YYYY-MM-DD",
  "session_summary": "Brief description of work done",
  "candidates": [
    {
      "what": "Description of the knowledge",
      "where": "target-file.md",
      "why": "Why it would have helped",
      "votes": {
        "skeptic": "YES/NO",
        "archivist": "YES/NO",
        "historian": "YES/NO",
        "devil": "YES/NO",
        "router": "YES/NO"
      },
      "outcome": "approved/rejected",
      "user_override": null,
      "reasoning_summary": "Key arguments for/against"
    }
  ]
}
```

If the user overrode any votes, set `user_override` to `"force_added"` or `"force_skipped"` with a note on why.

Report what was added, what was rejected, and that the vote history has been updated.
