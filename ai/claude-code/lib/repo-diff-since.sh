#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-23
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/repo-diff-since.sh
#
# For a local repo: fetch origin (read-only, never touches the working tree),
# then emit the full diff log (commits + diffs + stat) for AUTHOR since DATE
# from the origin default branch — so merged work not yet pulled locally is
# still captured. Output is large — redirect to a file per repo for the
# changelog skill to feed into synthesis.
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

# Read-only: the shared helper fetches origin and resolves the default branch
# (authoritatively, via ls-remote). No pull, so a dirty WIP tree is irrelevant
# and merged-but-unpulled work is still captured.
DEFAULT=$(bash "$(dirname "$0")/resolve-origin-default.sh" "$REPO") \
    || { echo "# WARN: $REPO has no resolvable origin default branch — skipped" >&2; exit 0; }

git -C "$REPO" log "$DEFAULT" \
    --author="$AUTHOR" \
    --since="$DATE" \
    --format="commit %h %s%n%aI" \
    -p --stat 2>/dev/null
