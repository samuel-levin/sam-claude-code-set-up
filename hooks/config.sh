#!/bin/bash
# Shared configuration for Claude Code hooks
# Source this from any hook script: source "$(dirname "$0")/config.sh"

# Anthropic API key for LLM-powered hooks
# Set this to your API key, or export ANTHROPIC_API_KEY in your shell profile
ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"

# Default model for hook LLM calls
HOOK_MODEL="${HOOK_MODEL:-claude-haiku-4-5-20251001}"

# Common paths
GUIDE_DIR="/Users/samuellevin/.claude/skills/x-darwin-guide"
