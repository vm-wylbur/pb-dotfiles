#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-06-02
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/gh-author-prs.sh
#
# Search GitHub PRs authored by @me and MERGED since DATE. Emits TSV:
#   repo#N<TAB>mergedAt<TAB>title
# (gh search prs exposes no mergedAt JSON field; for a merged PR closedAt IS
# the merge time, so we emit closedAt under the mergedAt column.) Silent if the
# gh CLI is missing. Used by the changelog skill: PR bodies frame the story
# (e.g. a batch of merged ansible PRs) beyond raw commits.
#
# NOTE: PR authorship is GitHub-account-scoped — repos whose work merges via
# agent-authored PRs or direct-to-main will under-report here. Commits + diffs
# remain the authoritative set for those.
#
# Warns to stderr if results hit LIMIT (silently truncated otherwise).
#
# Usage: bash lib/gh-author-prs.sh YYYY-MM-DD
#        LIMIT=300 bash lib/gh-author-prs.sh 2026-05-01

DATE=${1:-}
[ -z "$DATE" ] && { echo "usage: gh-author-prs.sh YYYY-MM-DD" >&2; exit 1; }
command -v gh &>/dev/null || exit 0

LIMIT=${LIMIT:-200}

# shellcheck disable=SC2209  # GH_PAGER=cat is an env-prefix for gh, not an assignment
out=$(GH_PAGER=cat gh search prs \
    --author="@me" \
    --merged \
    --merged-at=">=${DATE}" \
    --limit "$LIMIT" \
    --json repository,number,title,closedAt \
    --jq '.[] | "\(.repository.nameWithOwner)#\(.number)\t\(.closedAt)\t\(.title)"' \
    2>/dev/null)

[ -n "$out" ] && printf '%s\n' "$out"

n=$(printf '%s' "$out" | grep -c .)
[ "$n" -ge "$LIMIT" ] && \
    echo "# WARN: gh-author-prs hit LIMIT=$LIMIT ($n results) — may be truncated; rerun with a higher LIMIT" >&2
