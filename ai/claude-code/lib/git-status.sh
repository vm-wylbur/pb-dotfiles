#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-23
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/git-status.sh
#
# Print git status one-liner: repo | branch (dirty: N) | last commit.
# Silent if not in a git repo.

git rev-parse --git-dir &>/dev/null || exit 0

REPO=$(basename "$(git rev-parse --show-toplevel)")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
LAST=$(git log --oneline -1 2>/dev/null)

if [ "$DIRTY" -gt 0 ]; then
    echo "Git: ${REPO} | ${BRANCH} (dirty: ${DIRTY} files) | ${LAST}"
else
    echo "Git: ${REPO} | ${BRANCH} (clean) | ${LAST}"
fi
