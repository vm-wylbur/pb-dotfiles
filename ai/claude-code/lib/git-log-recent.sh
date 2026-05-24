#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-23
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/git-log-recent.sh
#
# Print last N commits touching a path, then flag closure markers
# (closes #N, fixes #N, deploys, merged, re-enable). Survey uses this
# to demote "pending" TODOs that git history shows are actually done.
#
# Usage: bash lib/git-log-recent.sh PATH [N]
#   PATH  required — file or directory to scan
#   N     optional — number of commits (default 20)

PATH_ARG=${1:-}
N=${2:-20}

if [ -z "$PATH_ARG" ]; then
    echo "usage: git-log-recent.sh PATH [N]" >&2
    exit 1
fi

git rev-parse --git-dir &>/dev/null || exit 0

LOG=$(git log --oneline -"${N}" -- "$PATH_ARG" 2>/dev/null)
[ -z "$LOG" ] && exit 0

echo "git log -${N} -- ${PATH_ARG}:"
echo "$LOG" | sed 's/^/  /'

CLOSURES=$(echo "$LOG" | grep -iE 'closes #|fixes #|resolves #|deploy|merge|re-enable|enable')
if [ -n "$CLOSURES" ]; then
    echo "  → closure markers — verify if any tracked TODO is actually done:"
    echo "$CLOSURES" | sed 's/^/    /'
fi
