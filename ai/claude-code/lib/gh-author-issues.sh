#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-23
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/gh-author-issues.sh
#
# Search GitHub issues/PRs authored by @me updated since DATE. Emits TSV:
#   repo#N<TAB>state<TAB>title
# Silent if gh CLI missing. Used by changelog skill for issue/PR context
# beyond raw commits (decisions, discussions, review findings).
#
# Usage: bash lib/gh-author-issues.sh YYYY-MM-DD
#        LIMIT=100 bash lib/gh-author-issues.sh 2026-05-01

DATE=${1:-}
[ -z "$DATE" ] && { echo "usage: gh-author-issues.sh YYYY-MM-DD" >&2; exit 1; }
command -v gh &>/dev/null || exit 0

LIMIT=${LIMIT:-50}

# shellcheck disable=SC2209  # GH_PAGER=cat is an env-prefix for gh, not an assignment
GH_PAGER=cat gh search issues \
    --author="@me" \
    --updated=">=${DATE}" \
    --limit "$LIMIT" \
    --json repository,title,number,state \
    --jq '.[] | "\(.repository.nameWithOwner)#\(.number)\t\(.state)\t\(.title)"' \
    2>/dev/null
