#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-23
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/gh-prs.sh
#
# Print open GH PRs for the repo in cwd.
# Silent if not in a git repo, no gh CLI, no GitHub remote, or no PRs.
#
# Usage:
#   bash lib/gh-prs.sh
#   LIMIT=20 bash lib/gh-prs.sh

git rev-parse --git-dir &>/dev/null || exit 0
command -v gh &>/dev/null || exit 0

REPO=$(basename "$(git rev-parse --show-toplevel)")
LIMIT=${LIMIT:-10}

PRS=$(gh pr list --state open --limit "$LIMIT" --json number,title,headRefName 2>/dev/null) || exit 0
FORMATTED=$(echo "$PRS" | jq -r '.[] | "  #\(.number)  \(.title)  [\(.headRefName)]"' 2>/dev/null)

if [ -n "$FORMATTED" ]; then
    echo "Open PRs (${REPO}):"
    echo "$FORMATTED"
fi
