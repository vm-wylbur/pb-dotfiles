#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-23
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/gh-issues.sh
#
# Print open GH issues for the repo in cwd. Optional label filter via $1.
# Silent if not in a git repo, no gh CLI, no GitHub remote, or no issues.
#
# Usage:
#   bash lib/gh-issues.sh            # all open issues, limit 10
#   bash lib/gh-issues.sh ops        # filter to label "ops"
#   LIMIT=20 bash lib/gh-issues.sh   # override limit

git rev-parse --git-dir &>/dev/null || exit 0
command -v gh &>/dev/null || exit 0

REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null) || REPO=$(basename "$(git rev-parse --show-toplevel)")
LIMIT=${LIMIT:-10}
LABEL=${1:-}

if [ -n "$LABEL" ]; then
    ISSUES=$(gh issue list --state open --limit "$LIMIT" --label "$LABEL" --json number,title 2>/dev/null) || exit 0
    HEADER="Open issues (${REPO}, label=${LABEL}):"
else
    ISSUES=$(gh issue list --state open --limit "$LIMIT" --json number,title 2>/dev/null) || exit 0
    HEADER="Open issues (${REPO}):"
fi

FORMATTED=$(echo "$ISSUES" | jq -r '.[] | "  #\(.number)  \(.title)"' 2>/dev/null)

if [ -n "$FORMATTED" ]; then
    echo "$HEADER"
    echo "$FORMATTED"
fi
