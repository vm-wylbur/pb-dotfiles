#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-23
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/gh-author-commits.sh
#
# Search all GitHub commits by @me since DATE across all repos. Emits TSV:
#   repo<TAB>sha<TAB>iso-date<TAB>first-line-of-message
# Silent if gh CLI missing. Used by changelog skill to discover which repos
# saw activity in the reporting window.
#
# Warns to stderr if results hit LIMIT (silently truncated otherwise).
#
# Usage: bash lib/gh-author-commits.sh YYYY-MM-DD
#        LIMIT=2000 bash lib/gh-author-commits.sh 2026-05-01

DATE=${1:-}
[ -z "$DATE" ] && { echo "usage: gh-author-commits.sh YYYY-MM-DD" >&2; exit 1; }
command -v gh &>/dev/null || exit 0

LIMIT=${LIMIT:-1000}

# shellcheck disable=SC2209  # GH_PAGER=cat is an env-prefix for gh, not an assignment
out=$(GH_PAGER=cat gh search commits \
    --author="@me" \
    --committer-date=">=${DATE}" \
    --sort=committer-date \
    --order=desc \
    --limit "$LIMIT" \
    --json repository,sha,commit \
    --jq '.[] | "\(.repository.fullName)\t\(.sha[0:7])\t\(.commit.committer.date)\t\(.commit.message | split("\n")[0])"' \
    2>/dev/null)

[ -n "$out" ] && printf '%s\n' "$out"

n=$(printf '%s' "$out" | grep -c .)
[ "$n" -ge "$LIMIT" ] && \
    echo "# WARN: gh-author-commits hit LIMIT=$LIMIT ($n results) — may be truncated; rerun with a higher LIMIT" >&2
