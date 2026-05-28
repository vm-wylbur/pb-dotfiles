#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-27
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/mem-store.sh
#
# Store a memory in claude-mem. Wraps the existing POST /store REST
# endpoint (already used by mem-capture.sh). Replaces the
# mcp__claude-mem__mem-store MCP tool surface for explicit calls.
#
# Input  (JSON on stdin):  {"content": "...", "tags": ["t1","t2"]?}
# Output (JSON on stdout): {"success": true, "memoryId": "...",
#                           "detectedType": "...", "tags": [...]}

set -uo pipefail

SETTINGS="${HOME}/.claude/settings.json"
SECRET=$(jq -r '.env.CLAUDE_MEM_SECRET // empty' "$SETTINGS" 2>/dev/null)
[ -z "$SECRET" ] && { echo '{"error":"CLAUDE_MEM_SECRET not in settings.json"}' >&2; exit 1; }

URL="${CLAUDE_MEM_URL:-http://snowball:3456}"
exec curl -fsS -m 30 \
    -H "X-Claude-Mem-Secret: $SECRET" \
    -H 'Content-Type: application/json' \
    -X POST "${URL}/store" \
    --data-binary @-
