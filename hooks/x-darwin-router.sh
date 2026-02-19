#!/bin/bash
# x-darwin context routing hook (Haiku-powered)
# Runs ONCE per session: uses Haiku to determine relevant x-darwin guide files,
# reads those files, and injects their contents as additionalContext.
# Subsequent prompts in the same session are skipped (no API call, no latency).

# Load shared config
source "$(dirname "$0")/config.sh"

# Read hook input from stdin
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# If no prompt or empty, bail
if [ -z "$PROMPT" ]; then
  echo '{"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": ""}}'
  exit 0
fi

# Session tracking: only run on the first prompt per session
FLAG_DIR="/tmp/x-darwin-hooks"
mkdir -p "$FLAG_DIR"

if [ -n "$SESSION_ID" ] && [ -f "$FLAG_DIR/$SESSION_ID" ]; then
  # Already ran for this session — skip
  echo '{"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": ""}}'
  exit 0
fi

# Mark this session as processed
if [ -n "$SESSION_ID" ]; then
  touch "$FLAG_DIR/$SESSION_ID"
fi

# Clean up old flag files (older than 24h) to avoid /tmp bloat
find "$FLAG_DIR" -type f -mtime +1 -delete 2>/dev/null

# If no API key, fall back to always-include files only
if [ -z "$ANTHROPIC_API_KEY" ]; then
  CONTEXT=""
  for f in architecture.md idiosyncrasies.md; do
    filepath="$GUIDE_DIR/$f"
    if [ -f "$filepath" ]; then
      CONTEXT="${CONTEXT}=== ${f} ===
$(cat "$filepath")

"
    fi
  done
  CONTEXT_JSON=$(printf '%s' "$CONTEXT" | jq -Rs .)
  echo "{\"hookSpecificOutput\": {\"hookEventName\": \"UserPromptSubmit\", \"additionalContext\": ${CONTEXT_JSON}}}"
  exit 0
fi

# List available files dynamically (so new files are picked up)
AVAILABLE_FILES=$(ls "$GUIDE_DIR"/*.md | xargs -I{} basename {} | grep -v "SKILL.md" | grep -v "routing-rules.md" | tr '\n' ', ' | sed 's/,$//')

# Build the Haiku request using jq --rawfile for safe escaping
SYSTEM_PROMPT="You are a routing agent. Given a user prompt and a skill index, determine which knowledge files are relevant.

Available files: ${AVAILABLE_FILES}

Rules:
- architecture.md and idiosyncrasies.md should ALWAYS be included for any x-darwin/code-related work.
- If the prompt is clearly NOT about x-darwin/mantl/code work (e.g. general chat, unrelated questions), return an empty list.
- When unsure if a file is relevant, INCLUDE it. Better to over-include than miss something.
- Read the skill index carefully — it describes when each file should be loaded.

Respond with ONLY a raw JSON array of filenames. No markdown fences, no explanation, no code blocks. Just the array.
Example: [\"architecture.md\", \"idiosyncrasies.md\", \"console-api-patterns.md\"]"

USER_MSG=$(jq -n --rawfile index "$GUIDE_DIR/SKILL.md" --arg prompt "$PROMPT" \
  '"User prompt: " + $prompt + "\n\nSkill index:\n" + $index')

API_PAYLOAD=$(jq -n \
  --arg model "$HOOK_MODEL" \
  --arg system "$SYSTEM_PROMPT" \
  --argjson user_msg "$USER_MSG" \
  '{
    model: $model,
    max_tokens: 256,
    system: $system,
    messages: [{ role: "user", content: $user_msg }]
  }')

# Call Haiku
RESPONSE=$(curl -s --max-time 15 \
  https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "$API_PAYLOAD")

# Extract text from response — use python for reliable JSON parsing
# (handles literal newlines in JSON string values that trip up jq)
FILE_LIST=$(python3 -c "
import json, sys
try:
    resp = json.loads(sys.stdin.read())
    text = resp['content'][0]['text'].strip()
    # Strip markdown code fences if present
    if text.startswith('\`\`\`'):
        text = text.split('\n', 1)[1] if '\n' in text else text[3:]
        if text.endswith('\`\`\`'):
            text = text[:-3].strip()
    files = json.loads(text)
    if isinstance(files, list):
        print(json.dumps(files))
    else:
        print('[]')
except:
    print('[]')
" <<< "$RESPONSE")

# If we got an empty list but shouldn't have (API error), use defaults
if [ "$FILE_LIST" = "[]" ] && [ -n "$RESPONSE" ]; then
  HAS_ERROR=$(python3 -c "
import json, sys
try:
    r = json.loads(sys.stdin.read())
    print('yes' if 'error' in r else 'no')
except:
    print('yes')
" <<< "$RESPONSE")
  if [ "$HAS_ERROR" = "yes" ]; then
    FILE_LIST='["architecture.md", "idiosyncrasies.md"]'
  fi
fi

# Read each selected file and build context
CONTEXT=""
for f in $(echo "$FILE_LIST" | jq -r '.[]'); do
  filepath="$GUIDE_DIR/$f"
  if [ -f "$filepath" ]; then
    CONTEXT="${CONTEXT}=== ${f} ===
$(cat "$filepath")

"
  fi
done

# Output JSON with additionalContext (jq -Rs handles newline escaping)
CONTEXT_JSON=$(printf '%s' "$CONTEXT" | jq -Rs .)
echo "{\"hookSpecificOutput\": {\"hookEventName\": \"UserPromptSubmit\", \"additionalContext\": ${CONTEXT_JSON}}}"
exit 0
