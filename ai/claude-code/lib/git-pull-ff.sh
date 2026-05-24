#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-23
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/git-pull-ff.sh
#
# Attempt git pull --ff-only. Silent on no-op or no-upstream. Prints one
# line if commits were pulled, or a WARN line on failure (diverged, etc.).
# Survey uses this as a precondition so findings reflect remote state.
#
# Usage: bash lib/git-pull-ff.sh

git rev-parse --git-dir &>/dev/null || exit 0
git rev-parse @{upstream} &>/dev/null || exit 0   # no tracking branch

# Skip silently on dirty tree — that's WIP, not stale state.
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "git-pull-ff: skipped (dirty tree — your WIP, not stale state)"
    exit 0
fi

OUTPUT=$(git pull --ff-only 2>&1)
RC=$?

if [ $RC -ne 0 ]; then
    REASON=$(echo "$OUTPUT" | grep -E '^(error|fatal):' | head -1 | sed -E 's/^(error|fatal): //')
    echo "git-pull-ff: FAILED — ${REASON:-unknown}"
    exit 0
fi

if ! echo "$OUTPUT" | grep -q "Already up to date"; then
    RANGE=$(echo "$OUTPUT" | grep -oE '[a-f0-9]+\.\.[a-f0-9]+' | head -1)
    NCOMMITS=$(echo "$OUTPUT" | grep -cE '^\s+\S+\s+\|\s+[0-9]+' || true)
    if [ -n "$RANGE" ]; then
        echo "git-pull-ff: pulled ${RANGE} (~${NCOMMITS} file changes)"
    else
        echo "git-pull-ff: pulled new commits"
    fi
fi
