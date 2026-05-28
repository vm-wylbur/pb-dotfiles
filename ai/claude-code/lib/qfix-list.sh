#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-27
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/qfix-list.sh
#
# List qfix queue entries. Wraps GET /qfix-list (added in
# vm-wylbur/claude-mem#3). Replaces mcp__claude-mem__queue-fix-list.
#
# Usage:
#   bash qfix-list.sh                              # open entries, limit 50
#   bash qfix-list.sh --target-repo hrdag-ansible
#   bash qfix-list.sh --status consumed --limit 10
#   bash qfix-list.sh --host scott
#
# Output (JSON on stdout): array of QueueFix entries (FIFO order).

set -uo pipefail

SETTINGS="${HOME}/.claude/settings.json"
SECRET=$(jq -r '.env.CLAUDE_MEM_SECRET // empty' "$SETTINGS" 2>/dev/null)
[ -z "$SECRET" ] && { echo '{"error":"CLAUDE_MEM_SECRET not in settings.json"}' >&2; exit 1; }

declare -a params=()
while [ $# -gt 0 ]; do
    case "$1" in
        --target-repo)  params+=("target_repo=$2"); shift 2 ;;
        --status)       params+=("status=$2");      shift 2 ;;
        --host)         params+=("host=$2");        shift 2 ;;
        --limit)        params+=("limit=$2");       shift 2 ;;
        -h|--help)
            sed -n '9,15p' "$0"; exit 0 ;;
        *)
            echo "{\"error\":\"unknown flag: $1\"}" >&2; exit 2 ;;
    esac
done

QS=""
if [ ${#params[@]} -gt 0 ]; then
    QS="?$(IFS='&'; echo "${params[*]}")"
fi

URL="${CLAUDE_MEM_URL:-http://snowball:3456}/qfix-list${QS}"
exec curl -fsS -m 30 -H "X-Claude-Mem-Secret: $SECRET" "$URL"
