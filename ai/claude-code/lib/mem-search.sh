#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-27
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/mem-search.sh
#
# Semantic search over claude-mem. Wraps POST /search (added in
# vm-wylbur/claude-mem#3, deployed to snowball 2026-05-27). Replaces
# the mcp__claude-mem__mem-search MCP tool.
#
# Input  (JSON on stdin):  {"query": "...", "limit": N?}
# Output (JSON on stdout): {"memories": [...]}
#
# Env overrides:
#   CLAUDE_MEM_URL — base URL, default http://snowball:3456

set -uo pipefail

SETTINGS="${HOME}/.claude/settings.json"
SECRET=$(jq -r '.env.CLAUDE_MEM_SECRET // empty' "$SETTINGS" 2>/dev/null)
[ -z "$SECRET" ] && { echo '{"error":"CLAUDE_MEM_SECRET not in settings.json"}' >&2; exit 1; }

URL="${CLAUDE_MEM_URL:-http://snowball:3456}"
exec curl -fsS -m 30 \
    -H "X-Claude-Mem-Secret: $SECRET" \
    -H 'Content-Type: application/json' \
    -X POST "${URL}/search" \
    --data-binary @-
