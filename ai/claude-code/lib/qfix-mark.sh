#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-27
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/qfix-mark.sh
#
# Mark a qfix entry consumed / escalated / superseded. Wraps POST
# /qfix-mark (added in vm-wylbur/claude-mem#3). Replaces
# mcp__claude-mem__queue-fix-mark.
#
# Input (JSON on stdin):
#   consumed:
#     {"id": N, "status": "consumed",
#      "consumed_by_commit": "abc123",
#      "consumed_in_repo": "hrdag-ansible",
#      "consumed_in_path": "roles/foo/tasks/main.yml"}
#   escalated:
#     {"id": N, "status": "escalated",
#      "escalation_reason": "needs human triage because ..."}
#   superseded:
#     {"id": N, "status": "superseded", "superseded_by": M}
#
# Output (JSON on stdout): {"success": true}

set -uo pipefail

SETTINGS="${HOME}/.claude/settings.json"
SECRET=$(jq -r '.env.CLAUDE_MEM_SECRET // empty' "$SETTINGS" 2>/dev/null)
[ -z "$SECRET" ] && { echo '{"error":"CLAUDE_MEM_SECRET not in settings.json"}' >&2; exit 1; }

URL="${CLAUDE_MEM_URL:-http://snowball:3456}"
exec curl -fsS -m 30 \
    -H "X-Claude-Mem-Secret: $SECRET" \
    -H 'Content-Type: application/json' \
    -X POST "${URL}/qfix-mark" \
    --data-binary @-
