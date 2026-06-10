#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-27 (provenance stamping added 2026-06-09)
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/mem-store.sh
#
# Store a memory in claude-mem. Wraps the existing POST /store REST
# endpoint (already used by mem-capture.sh). Replaces the
# mcp__claude-mem__mem-store MCP tool surface for explicit calls.
#
# This is the agent "remember" verb (Workstream B item W2, ratified
# neg-6b0a3bf5): writes are provenance-stamped with session_id / host /
# agent_id so the distiller can recognize a deliberate agent-write and
# defer to it (W8). The engine's /store contract (claude-mem PR #11):
# all three fields optional; absent = back-compat; empty string = 400 —
# so this script only sends fields it can actually resolve.
#
# Input  (JSON on stdin):  {"content": "...", "tags": ["t1","t2"]?,
#                           "session_id"?, "host"?, "agent_id"?}
#         caller-supplied provenance fields win over the env defaults
# Output (JSON on stdout): {"success": true, "memoryId": "...",
#                           "detectedType": "...", "tags": [...],
#                           "session_id"?, "host"?, "agent_id"?}
#         (the response echoes ACCEPTED INPUT, not a DB read-back —
#          persistence is asserted by the conformance suite via the
#          by-id read endpoint)
#
# Flags:
#   --dry-run   print the assembled payload to stdout, send nothing
#
# Provenance defaults:
#   session_id — $CLAUDE_CODE_SESSION_ID (set by the harness in tool shells)
#   host       — hostname -s
#   agent_id   — $CLAUDE_MEM_AGENT_ID if set, else negotiate-agent-id.sh
#                resolved from the current repo's CLAUDE.md (silently
#                omitted outside a repo with an identity line)

set -uo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
[ "${1:-}" = "--dry-run" ] && DRY_RUN=true

SETTINGS="${HOME}/.claude/settings.json"
SECRET=$(jq -r '.env.CLAUDE_MEM_SECRET // empty' "$SETTINGS" 2>/dev/null)
if ! $DRY_RUN && [ -z "$SECRET" ]; then
    echo '{"error":"CLAUDE_MEM_SECRET not in settings.json"}' >&2; exit 1
fi

SESSION_ID="${CLAUDE_CODE_SESSION_ID:-}"
HOST=$(hostname -s 2>/dev/null || true)
AGENT_ID="${CLAUDE_MEM_AGENT_ID:-}"
if [ -z "$AGENT_ID" ] && [ -x "$LIB_DIR/negotiate-agent-id.sh" ]; then
    AGENT_ID=$("$LIB_DIR/negotiate-agent-id.sh" 2>/dev/null || true)
fi

# Merge order: env defaults first, then stdin on top (caller wins).
# Empty-string values are stripped LAST so neither source can ship one
# (the /store contract 400s on '') — which gives callers an escape hatch:
# an explicit "" for a provenance field overrides the env default and is
# then stripped, i.e. "" means "send this write unstamped".
PAYLOAD=$(jq -c \
    --arg session_id "$SESSION_ID" --arg host "$HOST" --arg agent_id "$AGENT_ID" \
    '({session_id:$session_id, host:$host, agent_id:$agent_id} + .)
     | with_entries(select(.value != "" and .value != null))') || PAYLOAD=""
if [ -z "$PAYLOAD" ]; then
    echo '{"error":"stdin is not a JSON object; nothing sent"}' >&2; exit 1
fi
if [ -z "$AGENT_ID" ] && ! jq -e '.agent_id' >/dev/null 2>&1 <<<"$PAYLOAD"; then
    # non-fatal: the contract keeps provenance optional, but an unstamped
    # agent-write should never happen silently (W2/W8: the stamp is what
    # tells the distiller to defer)
    echo 'mem-store: warning — agent_id did not resolve; storing unstamped' >&2
fi

if $DRY_RUN; then
    printf '%s\n' "$PAYLOAD"
    exit 0
fi

URL="${CLAUDE_MEM_URL:-http://snowball:3456}"
exec curl -fsS -m 30 \
    -H "X-Claude-Mem-Secret: $SECRET" \
    -H 'Content-Type: application/json' \
    -X POST "${URL}/store" \
    --data-binary "$PAYLOAD"
