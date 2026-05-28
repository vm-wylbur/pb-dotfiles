#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-27
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/qfix-store.sh
#
# File a qfix (IaC-drift queue) entry. Wraps POST /qfix-store (added in
# vm-wylbur/claude-mem#3). Replaces mcp__claude-mem__queue-fix-store.
#
# Input  (JSON on stdin):  {
#     "target_repo": "hrdag-ansible",      // who encodes it
#     "host":        "scott",
#     "path":        "/etc/foo.conf",
#     "before_state": "...",                // optional; omit for creations
#     "after_state":  "...",                // required
#     "why":         "one-line reason",
#     "suggested_role": "roles/foo",        // optional
#     "who":         "PB",                   // who made the host change
#     "trust":       "PB",                   // optional
#     "metadata":    {...}                   // optional
# }
# Output (JSON on stdout): {"id": <number>}

set -uo pipefail

SETTINGS="${HOME}/.claude/settings.json"
SECRET=$(jq -r '.env.CLAUDE_MEM_SECRET // empty' "$SETTINGS" 2>/dev/null)
[ -z "$SECRET" ] && { echo '{"error":"CLAUDE_MEM_SECRET not in settings.json"}' >&2; exit 1; }

URL="${CLAUDE_MEM_URL:-http://snowball:3456}"
exec curl -fsS -m 30 \
    -H "X-Claude-Mem-Secret: $SECRET" \
    -H 'Content-Type: application/json' \
    -X POST "${URL}/qfix-store" \
    --data-binary @-
