#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-23
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/repo-diff-since.sh
#
# For a local repo: ff-pull (silent on dirty tree), then emit full diff log
# (commits + diffs + stat) for AUTHOR since DATE. Output is large — redirect
# to a file per repo for the changelog skill to feed into synthesis.
#
# Silent and exits 0 if REPO is not a git repo (skip-missing semantics so
# changelog can iterate over a repo list without pre-checking each).
#
# Usage: bash lib/repo-diff-since.sh REPO_PATH YYYY-MM-DD
#        AUTHOR=alice bash lib/repo-diff-since.sh ~/projects/foo 2026-05-01

REPO=${1:-}
DATE=${2:-}
if [ -z "$REPO" ] || [ -z "$DATE" ]; then
    echo "usage: repo-diff-since.sh REPO_PATH YYYY-MM-DD" >&2
    exit 1
fi
[ -d "$REPO/.git" ] || exit 0

AUTHOR=${AUTHOR:-pball}

# Pull only if clean; otherwise leave WIP alone.
if [ -z "$(git -C "$REPO" status --porcelain 2>/dev/null)" ]; then
    git -C "$REPO" fetch --quiet origin 2>/dev/null
    PULL=$(git -C "$REPO" pull --ff-only 2>&1)
    if echo "$PULL" | grep -qE '^(error|fatal):'; then
        echo "# WARN: pull --ff-only failed in $REPO — diff reflects local state" >&2
    fi
else
    echo "# WARN: $REPO has uncommitted changes — skipped pull, using local state" >&2
fi

git -C "$REPO" log \
    --author="$AUTHOR" \
    --since="$DATE" \
    --format="commit %h %s%n%aI" \
    -p --stat 2>/dev/null
