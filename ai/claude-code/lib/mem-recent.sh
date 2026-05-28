#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-27
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/mem-recent.sh
#
# Fetch recent memories from claude-mem. Wraps the existing GET /recent
# REST endpoint (already used by mem-inject.sh). Exposes the
# mcp__claude-mem__mem-recent equivalent for ad-hoc queries from skills
# or scripts.
#
# Usage:
#   bash mem-recent.sh                       # last 3, global
#   bash mem-recent.sh --n 10                # last 10, global
#   bash mem-recent.sh --project pb-dotfiles # last 3, tag-filtered
#   bash mem-recent.sh --project foo --n 20
#
# Output (JSON on stdout): {"memories": [...]}

set -uo pipefail

SETTINGS="${HOME}/.claude/settings.json"
SECRET=$(jq -r '.env.CLAUDE_MEM_SECRET // empty' "$SETTINGS" 2>/dev/null)
[ -z "$SECRET" ] && { echo '{"error":"CLAUDE_MEM_SECRET not in settings.json"}' >&2; exit 1; }

N=3
PROJECT=""
while [ $# -gt 0 ]; do
    case "$1" in
        --n)        N=$2;       shift 2 ;;
        --project)  PROJECT=$2; shift 2 ;;
        -h|--help)
            sed -n '8,16p' "$0"; exit 0 ;;
        *)
            echo "{\"error\":\"unknown flag: $1\"}" >&2; exit 2 ;;
    esac
done

URL="${CLAUDE_MEM_URL:-http://snowball:3456}/recent?n=${N}"
[ -n "$PROJECT" ] && URL="${URL}&project=${PROJECT}"

exec curl -fsS -m 30 -H "X-Claude-Mem-Secret: $SECRET" "$URL"
